import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/diagnosis_model.dart';

/// Exception thrown when the uploaded image is definitely not a plant.
class NotAPlantException implements Exception {
  final String message;
  const NotAPlantException([this.message = 'Please click a picture of a plant leaf, fruit, or flower']);

  @override
  String toString() => message;
}

enum ScanMode { identify, diagnose }

const _invalidPlantNames = {
  'plant', 'plant species', 'common plant name', 'botanical scientific name',
  'unknown', 'unknown plant', 'unidentified', 'unidentified plant', '',
};

bool _isValidPlantName(String? name) =>
    name != null && !_invalidPlantNames.contains(name.trim().toLowerCase());

/// Primary Gemini Vision, Plant.id v3, and Pl@ntNet AI engine.
class ScanService {
  Future<DiagnosisModel> identify({
    required Uint8List imageBytes,
    required ScanMode mode,
    String? plantId,
  }) async {
    assert(mode != ScanMode.diagnose || plantId != null, 'plantId is required for diagnose mode');

    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final plantIdKey = dotenv.env['PLANTID_API_KEY'] ?? '';
    final plantNetKey = dotenv.env['PLANTNET_API_KEY'] ?? '';

    final strippedBytes = await compute(_stripExifIsolate, imageBytes);
    final base64Image = base64Encode(strippedBytes);

    // ── 1. Google Gemini Multimodal Vision API ──
    if (geminiKey.isNotEmpty) {
      try {
        final result = await _tryGemini(geminiKey, base64Image, mode);
        if (result != null) return result;
      } catch (e) {
        if (e is NotAPlantException) rethrow;
        debugPrint('Gemini Vision API Error: $e');
      }
    }

    // ── 2. Plant.id (Kindwise) API v3 ──
    if (plantIdKey.isNotEmpty) {
      try {
        final result = await _tryPlantId(plantIdKey, base64Image, mode);
        if (result != null) return result;
      } catch (e) {
        if (e is NotAPlantException) rethrow;
        debugPrint('Plant.id API Error: $e');
      }
    }

    // ── 3. Pl@ntNet API (Multi-Organ Fallback) ──
    if (plantNetKey.isNotEmpty) {
      try {
        final result = await _tryPlantNet(plantNetKey, strippedBytes);
        if (result != null) return result;
      } catch (e) {
        if (e is NotAPlantException) rethrow;
        debugPrint('Pl@ntNet API Error: $e');
      }
    }

    throw const NotAPlantException(
      'Could not identify this plant. Please try again with a clearer photo showing the leaf, fruit, or flower.',
    );
  }

  // ── Gemini Vision API ──
  Future<DiagnosisModel?> _tryGemini(String apiKey, String base64Image, ScanMode mode) async {
    final geminiUrl = dotenv.env['GEMINI_API_URL'] ??
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
    
    final response = await http.post(
      Uri.parse('$geminiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": """
You are an expert botanical species classifier and agricultural plant pathologist.
Analyze this photo carefully.

BOTANICAL RECOGNITION RULES:
1. Accept ANY photo containing a plant part as a VALID plant ("is_plant": true).
   This includes:
   - A single leaf, leaf margin, or leaf close-up
   - A flower blossom, petal, or inflorescence
   - A fruit, berry, vegetable, tomato, chili, or seed pod
   - A stem, branch, or whole potted plant/tree
2. ONLY set "is_plant": false if the photo contains ZERO botanical material (e.g. cars, shoes, people, electronics).
3. Return the exact plant species common name (e.g. "Tomato", "Coleus", "Tulsi", "Rose", "Mango", "Potato", "Monstera") and scientific name.
4. Calculate actual visual confidence probability score (0.50 - 0.99).
5. Inspect for fungal, bacterial, or pest diseases on fruits, leaves, and stems:
   - If diseased: set "is_healthy": false, specify disease name (e.g. "Tomato Late Blight", "Fruit Rot", "Powdery Mildew"), description, and 3-5 specific treatment steps.
   - If healthy: set "is_healthy": true, "diseases": [].

Respond with ONLY valid JSON:
{
  "is_plant": true,
  "plant_name": "Common Plant Name",
  "scientific_name": "Botanical Scientific Name",
  "confidence": 0.92,
  "description": "Rich botanical description...",
  "is_healthy": false,
  "diseases": [
    {
      "name": "Disease Name",
      "probability": 0.90,
      "description": "Pathogen symptoms and cause...",
      "treatments": ["Treatment step 1", "Treatment step 2"]
    }
  ]
}
"""
              },
              {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
            ]
          }
        ],
        "generationConfig": {"response_mime_type": "application/json", "temperature": 0.2}
      }),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final parts = (candidates.first as Map<String, dynamic>)['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;

    String jsonText = parts.first['text'] as String? ?? '{}';
    jsonText = jsonText.trim();
    if (jsonText.startsWith('```json')) jsonText = jsonText.substring(7);
    if (jsonText.startsWith('```')) jsonText = jsonText.substring(3);
    if (jsonText.endsWith('```')) jsonText = jsonText.substring(0, jsonText.length - 3);

    final parsed = jsonDecode(jsonText.trim()) as Map<String, dynamic>;
    if (!(parsed['is_plant'] as bool? ?? true)) {
      throw const NotAPlantException('This does not appear to be a plant. Please take a photo of a leaf, fruit, or flower.');
    }

    final plantName = parsed['plant_name'] as String?;
    if (!_isValidPlantName(plantName)) return null;

    final sciName = parsed['scientific_name'] as String?;
    final validPlantName = plantName!;
    final validSciName = _isValidPlantName(sciName) ? sciName! : validPlantName;
    final isHealthy = parsed['is_healthy'] as bool? ?? true;

    final diseases = !isHealthy
        ? ((parsed['diseases'] as List<dynamic>?) ?? []).map((d) {
            final dMap = d as Map<String, dynamic>;
            return DiseaseResult(
              name: dMap['name'] as String? ?? 'Plant Health Issue',
              probability: (dMap['probability'] as num?)?.toDouble() ?? 0.85,
              description: dMap['description'] as String? ?? 'Disease detected by AI visual analysis.',
              treatments: (dMap['treatments'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
                  const ['Remove affected parts and apply an appropriate organic fungicide.'],
            );
          }).toList()
        : <DiseaseResult>[];

    return DiagnosisModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      plantName: validPlantName,
      scientificName: validSciName,
      confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.85,
      description: parsed['description'] as String? ?? '$validPlantName ($validSciName) is a widely cultivated botanical species.',
      diseases: diseases,
      recommendations: _getSmartRecommendations(validPlantName),
      scannedAt: DateTime.now(),
    );
  }

  // ── Plant.id (Kindwise) v3 ──
  Future<DiagnosisModel?> _tryPlantId(String apiKey, String base64Image, ScanMode mode) async {
    final plantIdUrl = dotenv.env['PLANTID_API_URL'] ?? 'https://api.plant.id/v3/identification';
    final response = await http.post(
      Uri.parse('$plantIdUrl?details=description,treatment,common_names,scientific_name'),
      headers: {'Api-Key': apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'images': [base64Image], 'health': 'all'}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) return null;

    final result = (jsonDecode(response.body) as Map<String, dynamic>)['result'] as Map<String, dynamic>?;
    final isPlantObj = result?['is_plant'] as Map<String, dynamic>?;
    final isPlantBinary = isPlantObj?['binary'] as bool? ?? true;
    final isPlantProb = (isPlantObj?['probability'] as num?)?.toDouble() ?? 1.0;

    // Only reject if model is over 95% certain that it is NOT a plant
    if (!isPlantBinary && isPlantProb < 0.05) {
      throw const NotAPlantException('Please click a picture of a plant leaf, fruit, or flower');
    }

    final suggestions = result?['classification']?['suggestions'] as List<dynamic>?;
    if (suggestions == null || suggestions.isEmpty) return null;

    final top = suggestions.first as Map<String, dynamic>;
    final details = top['details'] as Map<String, dynamic>?;
    final commonNames = (details?['common_names'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    final rawName = top['name'] as String? ?? 'Plant';
    final plantName = (commonNames != null && commonNames.isNotEmpty) ? commonNames.first : rawName;
    if (!_isValidPlantName(plantName)) return null;

    final sciName = details?['scientific_name'] as String? ?? rawName;
    
    // Check disease health assessment
    final isHealthyObj = result?['is_healthy'] ?? (result?['disease'] ?? result?['health_assessment'])?['is_healthy'];
    final isHealthyBinary = isHealthyObj is Map ? (isHealthyObj['binary'] as bool? ?? true) : (isHealthyObj is bool ? isHealthyObj : true);
    final isHealthyProb = isHealthyObj is Map ? ((isHealthyObj['probability'] as num?)?.toDouble() ?? 1.0) : 1.0;

    final diseaseSuggestions = (result?['disease']?['suggestions'] ??
        (result?['health_assessment']?['diseases'] ?? result?['diseases'])) as List<dynamic>?;

    final diseases = (!isHealthyBinary || isHealthyProb < 0.60) && diseaseSuggestions != null
        ? diseaseSuggestions.where((d) => ((d['probability'] as num?)?.toDouble() ?? 0.0) > 0.15).map((d) {
            final dMap = d as Map<String, dynamic>;
            final dDetails = dMap['details'] as Map<String, dynamic>?;
            final dTreat = dDetails?['treatment'] as Map<String, dynamic>?;
            final treatments = dTreat?.values.whereType<List>().expand((l) => l.map((e) => e.toString())).toList() ??
                const ['Remove affected parts and apply an appropriate organic fungicide spray.'];
            
            final descVal = dDetails?['description'];
            final descStr = descVal is Map ? descVal['value'] as String? : (descVal as String?);

            return DiseaseResult(
              name: dMap['name'] as String? ?? 'Plant Disease',
              probability: (dMap['probability'] as num?)?.toDouble() ?? 0.80,
              description: (descStr != null && descStr.isNotEmpty) ? descStr : 'Disease detected by botanical visual analysis.',
              treatments: treatments,
            );
          }).toList()
        : <DiseaseResult>[];

    final descVal = details?['description'];
    final plantDesc = descVal is Map ? descVal['value'] as String? : (descVal as String?);

    return DiagnosisModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      plantName: plantName,
      scientificName: sciName,
      confidence: (top['probability'] as num?)?.toDouble() ?? 0.88,
      description: plantDesc ?? '$plantName ($sciName) is a recognized botanical species.',
      diseases: diseases,
      recommendations: _getSmartRecommendations(plantName),
      scannedAt: DateTime.now(),
    );
  }

  // ── Pl@ntNet API ──
  Future<DiagnosisModel?> _tryPlantNet(String apiKey, Uint8List strippedBytes) async {
    final plantNetUrl = dotenv.env['PLANTNET_API_URL'] ?? 'https://my-api.plantnet.org/v2/identify/all';
    final request = http.MultipartRequest('POST', Uri.parse('$plantNetUrl?api-key=$apiKey'))
      ..files.add(http.MultipartFile.fromBytes('images', strippedBytes, filename: 'plant_scan.jpg'))
      ..fields['organs'] = 'auto';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) return null;

    final results = (jsonDecode(response.body) as Map<String, dynamic>)['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final top = results.first as Map<String, dynamic>;
    final score = (top['score'] as num?)?.toDouble() ?? 0.0;
    if (score < 0.10) throw const NotAPlantException('Please click a picture of a plant');

    final species = top['species'] as Map<String, dynamic>?;
    final sciName = species?['scientificNameWithoutAuthor'] as String? ?? '';
    final commonNames = (species?['commonNames'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    final plantName = (commonNames != null && commonNames.isNotEmpty) ? commonNames.first : sciName;
    if (!_isValidPlantName(plantName)) return null;

    return DiagnosisModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      plantName: plantName,
      scientificName: sciName,
      confidence: score,
      description: '$plantName ($sciName) is a recognized plant species.',
      diseases: const [],
      recommendations: _getSmartRecommendations(plantName),
      scannedAt: DateTime.now(),
    );
  }

  // ── Care recommendations map lookup ──
  static const _careTipsMap = <String, List<String>>{
    'tomato': [
      'Water at soil level early in the morning to keep foliage dry.',
      'Prune lower leaves that touch the soil to prevent fungal spores.',
      'Support heavy fruit trusses with stakes or cages.',
      'Provide 6-8 hours of direct daily sunlight.',
    ],
    'coleus': [
      'Provide bright, indirect light to maintain vivid leaf colors.',
      'Pinch off flower buds to encourage bushier foliage growth.',
      'Water regularly but avoid waterlogged soil.',
    ],
    'tulsi': [
      'Place in full sunlight for at least 6 hours daily.',
      'Water when the top layer of soil feels dry.',
      'Prune regularly to promote bushy growth and prevent flowering.',
    ],
    'rose': [
      'Water deeply at the base, avoiding wet foliage.',
      'Prune dead blooms to encourage new flowering.',
      'Apply balanced fertilizer every 4-6 weeks during growing season.',
    ],
    'monstera': [
      'Provide bright, indirect light; avoid direct sun.',
      'Water when the top inch of soil feels dry.',
      'Wipe leaves with a damp cloth to remove dust.',
    ],
  };

  static List<String> _getSmartRecommendations(String plantName) {
    final lower = plantName.toLowerCase();
    for (final entry in _careTipsMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return const [
      'Water when top inch of soil feels dry.',
      'Provide bright, indirect sunlight.',
      'Ensure pot has adequate drainage holes.',
    ];
  }

  static Uint8List _stripExifIsolate(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final processed = (decoded.width > 1280 || decoded.height > 1280)
        ? (decoded.width >= decoded.height
            ? img.copyResize(decoded, width: 1280)
            : img.copyResize(decoded, height: 1280))
        : decoded;
    return Uint8List.fromList(img.encodeJpg(processed, quality: 88));
  }
}
