import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/diagnosis_model.dart';

/// Exception thrown when the uploaded image is not a plant or no plant could be detected.
class NotAPlantException implements Exception {
  final String message;
  const NotAPlantException([this.message = 'Please click a picture of a plant']);

  @override
  String toString() => message;
}

/// Scan mode determines the API behavior.
enum ScanMode {
  /// Identify an unknown plant from a photo.
  identify,

  /// Diagnose health issues on a known plant.
  diagnose,
}

/// Names considered invalid / generic that mean the model failed to identify.
const _invalidPlantNames = {
  'plant',
  'plant species',
  'common plant name',
  'botanical scientific name',
  'unknown',
  'unknown plant',
  'unidentified',
  'unidentified plant',
  '',
};

/// Returns true if [name] is a real, specific plant name (not generic garbage).
bool _isValidPlantName(String? name) {
  if (name == null) return false;
  return !_invalidPlantNames.contains(name.trim().toLowerCase());
}

/// Handles plant scan/identification & health assessment via Gemini Vision API (Primary),
/// Plant.id (Kindwise) API v3, and Pl@ntNet API.
///
/// Disease detection is FULLY DYNAMIC — only the AI models decide if a plant is diseased.
/// Accurately detects pathogens on leaves, fruits, berries, stems, and flowers.
class ScanService {
  Future<DiagnosisModel> identify({
    required Uint8List imageBytes,
    required ScanMode mode,
    String? plantId,
  }) async {
    assert(
      mode != ScanMode.diagnose || plantId != null,
      'plantId is required for diagnose mode',
    );

    final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final plantIdApiKey = dotenv.env['PLANTID_API_KEY'] ?? '';
    final plantNetApiKey = dotenv.env['PLANTNET_API_KEY'] ?? '';

    // Strip EXIF metadata & optimize resolution in a separate isolate
    final strippedBytes = await compute(_stripExifIsolate, imageBytes);
    final base64Image = base64Encode(strippedBytes);

    // ── 1. PRIMARY: Google Gemini 3.7 Flash Vision API ──
    if (geminiApiKey.isNotEmpty) {
      try {
        final result = await _tryGemini(geminiApiKey, base64Image, mode);
        if (result != null) return result;
      } catch (e) {
        if (e is NotAPlantException) rethrow;
        debugPrint('Gemini Vision API Error: $e');
      }
    }

    // ── 2. FALLBACK: Plant.id (Kindwise) API v3 ──
    if (plantIdApiKey.isNotEmpty) {
      try {
        final result = await _tryPlantId(plantIdApiKey, base64Image, mode);
        if (result != null) return result;
      } catch (e) {
        if (e is NotAPlantException) rethrow;
        debugPrint('Plant.id API Error: $e');
      }
    }

    // ── 3. FALLBACK: Pl@ntNet API (identification only, no disease detection) ──
    if (plantNetApiKey.isNotEmpty) {
      try {
        final result = await _tryPlantNet(plantNetApiKey, strippedBytes);
        if (result != null) return result;
      } catch (e) {
        if (e is NotAPlantException) rethrow;
        debugPrint('Pl@ntNet API Error: $e');
      }
    }

    // ── 4. All APIs failed ──
    throw const NotAPlantException(
      'Could not identify this plant. Please try again with a clearer photo showing the full leaf, fruit, or flower.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Gemini Vision API — returns DYNAMIC disease results from AI model only
  // ═══════════════════════════════════════════════════════════════════════════
  Future<DiagnosisModel?> _tryGemini(String apiKey, String base64Image, ScanMode mode) async {
    final geminiUrl = dotenv.env['GEMINI_API_URL'] ??
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.7-flash:generateContent';
    final uri = Uri.parse('$geminiUrl?key=$apiKey');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": """
You are an expert botanical species classifier and agricultural plant pathologist.
Analyze this photo carefully.

IDENTIFICATION RULES:
1. Identify the exact plant species from the photo. Return the common name (e.g. "Tomato", "Coleus", "Tulsi", "Rose", "Mango", "Potato", "Chili Pepper", "Eggplant", "Neem", "Monstera") and scientific name.
2. Accept photos of any plant part: leaves, fruits, berries, seed pods, flowers, stems, branches, bark, or whole plants.
3. ONLY set "is_plant" to false if the image contains NO botanical material (e.g., cars, shoes, electronics, people).
4. Provide a dynamic visual confidence score (decimal between 0.40 and 0.99).
5. Write a rich, 2-3 sentence description of the plant species.

COMPREHENSIVE PATHOLOGY & DISEASE DETECTION RULES:
6. Carefully inspect ALL parts of the plant in the photo:
   - FRUITS/BERRIES: Look for brown/black sunken rot spots, mold growth, concentric ring lesions, leathery patches, blossom end rot, Late Blight (Phytophthora infestans), Anthracnose, Buckeye rot, or soft rot.
   - LEAVES/FOLIAGE: Look for fungal spots, chlorosis (yellowing), powdery mildew, downy mildew, leaf curl, blights, necrosis, or pest webbing.
   - STEMS/VINES: Look for dark lesions, cankers, wilting, or vascular browning.
7. IF ANY DISEASE OR PEST DAMAGE IS DETECTED ON FRUITS, LEAVES, OR STEMS:
   - Set "is_healthy": false
   - Name the exact disease (e.g. "Tomato Late Blight", "Fruit Rot (Anthracnose)", "Blossom End Rot", "Early Blight", "Powdery Mildew", "Bacterial Spot")
   - Provide a detailed "About Pathogen" description explaining the cause and symptoms
   - Provide 3-5 specific, practical, actionable treatment and prevention steps (cultural practices, organic fungicides like copper/neem, watering adjustments, pruning infected fruit/leaves)
8. IF THE PLANT IS HEALTHY (vibrant foliage/fruit, no rot, no lesions, no mold, no pests):
   - Set "is_healthy": true
   - Return an empty "diseases" array: []
   - Note: Natural colored variegation (like red/purple in Coleus) is healthy, NOT a disease.

Format response strictly as valid JSON matching this schema:
{
  "is_plant": true,
  "plant_name": "Common Plant Name",
  "scientific_name": "Botanical Scientific Name",
  "confidence": 0.92,
  "description": "Rich botanical description of the species...",
  "is_healthy": false,
  "diseases": [
    {
      "name": "Disease Name",
      "probability": 0.90,
      "description": "Detailed description of pathogen cause, symptoms, and impact...",
      "treatments": [
        "Actionable treatment step 1",
        "Actionable treatment step 2",
        "Actionable treatment step 3"
      ]
    }
  ]
}
"""
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json",
          "temperature": 0.2
        }
      }),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final firstCandidate = candidates.first as Map<String, dynamic>;
    final content = firstCandidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;

    final jsonText = parts.first['text'] as String? ?? '';
    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;

    final isPlant = parsed['is_plant'] as bool? ?? true;
    if (!isPlant) {
      throw const NotAPlantException('This does not appear to be a plant. Please take a photo of a plant leaf, fruit, or flower.');
    }

    final plantName = parsed['plant_name'] as String?;
    final scientificName = parsed['scientific_name'] as String?;

    // If Gemini returned generic garbage, fall through to next API
    if (!_isValidPlantName(plantName)) {
      debugPrint('Gemini returned generic name "$plantName", falling through to Plant.id');
      return null;
    }

    final confidence = (parsed['confidence'] as num?)?.toDouble() ?? 0.85;
    final description = parsed['description'] as String?;
    final isHealthy = parsed['is_healthy'] as bool? ?? true;

    // DYNAMIC diseases — only populated if the AI model detected real symptoms
    List<DiseaseResult> diseases = [];
    if (!isHealthy) {
      final diseaseList = parsed['diseases'] as List<dynamic>?;
      if (diseaseList != null && diseaseList.isNotEmpty) {
        diseases = diseaseList.map((d) {
          final dMap = d as Map<String, dynamic>;
          final name = dMap['name'] as String? ?? 'Plant Health Issue';
          final prob = (dMap['probability'] as num?)?.toDouble() ?? 0.85;
          final desc = dMap['description'] as String? ?? '';
          final treatments = (dMap['treatments'] as List<dynamic>?)
                  ?.map((t) => t.toString())
                  .toList() ??
              [];

          return DiseaseResult(
            name: name,
            probability: prob,
            description: desc.isNotEmpty ? desc : 'Disease detected by AI visual pathology analysis.',
            treatments: treatments.isNotEmpty
                ? treatments
                : const [
                    'Remove and dispose of severely infected plant parts to prevent spore spread.',
                    'Apply an appropriate organic copper fungicide spray.',
                    'Avoid overhead watering; water the soil at the base in early morning.',
                  ],
          );
        }).toList();
      }
    }

    final validPlantName = plantName!;
    final validSciName = _isValidPlantName(scientificName) ? scientificName! : validPlantName;

    return DiagnosisModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      plantName: validPlantName,
      scientificName: validSciName,
      confidence: confidence,
      description: (description != null && description.length > 20)
          ? description
          : _getPlantDescription(validPlantName, validSciName, null, null),
      diseases: diseases,
      recommendations: _getSmartRecommendations(validPlantName),
      scannedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Plant.id (Kindwise) API v3 — DYNAMIC disease detection from API response
  // ═══════════════════════════════════════════════════════════════════════════
  Future<DiagnosisModel?> _tryPlantId(String apiKey, String base64Image, ScanMode mode) async {
    final plantIdUrl = dotenv.env['PLANTID_API_URL'] ??
        'https://api.plant.id/v3/identification';
    final uri = Uri.parse('$plantIdUrl?details=description,treatment,common_names,scientific_name');

    final response = await http.post(
      uri,
      headers: {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'images': [base64Image],
        'health': 'all',
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;

    final isPlantObj = result?['is_plant'] as Map<String, dynamic>?;
    final isPlantBinary = isPlantObj?['binary'] as bool? ?? true;
    final isPlantProb = (isPlantObj?['probability'] as num?)?.toDouble() ?? 1.0;

    if (!isPlantBinary && isPlantProb < 0.05) {
      throw const NotAPlantException('Please click a picture of a plant');
    }

    final classification = result?['classification'] as Map<String, dynamic>?;
    final suggestions = classification?['suggestions'] as List<dynamic>?;

    String plantName = '';
    String scientificName = '';
    String? plantDescription;
    double speciesConfidence = isPlantProb;

    if (suggestions != null && suggestions.isNotEmpty) {
      final topSuggestion = suggestions.first as Map<String, dynamic>;
      speciesConfidence = (topSuggestion['probability'] as num?)?.toDouble() ?? isPlantProb;
      final details = topSuggestion['details'] as Map<String, dynamic>?;
      final commonNames = (details?['common_names'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();

      final rawName = topSuggestion['name'] as String? ?? '';

      if (commonNames != null && commonNames.isNotEmpty) {
        plantName = commonNames.first;
        scientificName = rawName;
      } else {
        plantName = rawName;
        scientificName = details?['scientific_name'] as String? ?? rawName;
      }

      final descObj = details?['description'];
      if (descObj is Map<String, dynamic>) {
        plantDescription = descObj['value'] as String?;
      } else if (descObj is String) {
        plantDescription = descObj;
      }
      plantDescription ??= _getPlantDescription(plantName, scientificName, commonNames, null);
    }

    if (!_isValidPlantName(plantName)) return null;

    // DYNAMIC disease detection from Plant.id health assessment API
    final diseaseObj = (result?['disease'] ?? result?['health_assessment']) as Map<String, dynamic>?;
    final isHealthyObj = diseaseObj?['is_healthy'] ?? result?['is_healthy'];
    final isHealthyProb = (isHealthyObj is Map
            ? (isHealthyObj['probability'] as num?)?.toDouble()
            : (isHealthyObj is num ? isHealthyObj.toDouble() : null)) ??
        0.9;
    final diseaseSuggestions = (diseaseObj?['suggestions'] ??
        diseaseObj?['diseases'] ??
        result?['diseases']) as List<dynamic>?;

    List<DiseaseResult> diseases = [];
    if (isHealthyProb < 0.60 && diseaseSuggestions != null && diseaseSuggestions.isNotEmpty) {
      diseases = diseaseSuggestions.where((d) {
        final dMap = d as Map<String, dynamic>;
        final dProb = (dMap['probability'] as num?)?.toDouble() ?? 0.0;
        return dProb > 0.25;
      }).map((d) {
        final dMap = d as Map<String, dynamic>;
        final dName = dMap['name'] as String? ?? 'Plant Disease';
        final dProb = (dMap['probability'] as num?)?.toDouble() ?? 0.80;
        final dDetails = dMap['details'] as Map<String, dynamic>?;
        final descObj = dDetails?['description'];
        String? dDesc;
        if (descObj is Map<String, dynamic>) {
          dDesc = descObj['value'] as String?;
        } else if (descObj is String) {
          dDesc = descObj;
        }

        final dTreatment = dDetails?['treatment'] as Map<String, dynamic>?;
        List<String> treatmentList = [];
        if (dTreatment != null) {
          if (dTreatment['biological'] != null) {
            treatmentList.addAll((dTreatment['biological'] as List).map((e) => e.toString()));
          }
          if (dTreatment['chemical'] != null) {
            treatmentList.addAll((dTreatment['chemical'] as List).map((e) => e.toString()));
          }
          if (dTreatment['prevention'] != null) {
            treatmentList.addAll((dTreatment['prevention'] as List).map((e) => e.toString()));
          }
        }

        return DiseaseResult(
          name: dName,
          probability: dProb,
          description: (dDesc != null && dDesc.isNotEmpty) ? dDesc : 'Disease detected by Plant.id health assessment.',
          treatments: treatmentList.isNotEmpty ? treatmentList : const ['Consult a local plant nursery for treatment advice.'],
        );
      }).toList();
    }

    return DiagnosisModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      plantName: plantName,
      scientificName: scientificName,
      confidence: speciesConfidence,
      description: plantDescription ?? _getPlantDescription(plantName, scientificName, null, null),
      diseases: diseases,
      recommendations: _getSmartRecommendations(plantName),
      scannedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Pl@ntNet API — identification only, NO disease detection
  // ═══════════════════════════════════════════════════════════════════════════
  Future<DiagnosisModel?> _tryPlantNet(String apiKey, Uint8List strippedBytes) async {
    final plantNetUrl = dotenv.env['PLANTNET_API_URL'] ??
        'https://my-api.plantnet.org/v2/identify/all';
    final uri = Uri.parse('$plantNetUrl?api-key=$apiKey');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'images',
        strippedBytes,
        filename: 'plant_scan.jpg',
      ),
    );
    request.fields['organs'] = 'auto';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final topResult = results.first as Map<String, dynamic>;
    final score = (topResult['score'] as num?)?.toDouble() ?? 0.0;

    if (score < 0.10) {
      throw const NotAPlantException('Please click a picture of a plant');
    }

    final species = topResult['species'] as Map<String, dynamic>?;
    final scientificName = species?['scientificNameWithoutAuthor'] as String? ?? '';
    final commonNames = (species?['commonNames'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final plantName = (commonNames != null && commonNames.isNotEmpty)
        ? commonNames.first
        : scientificName;

    if (!_isValidPlantName(plantName)) return null;

    return DiagnosisModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      plantName: plantName,
      scientificName: scientificName,
      confidence: score,
      description: _getPlantDescription(plantName, scientificName, commonNames, null),
      diseases: const [],
      recommendations: _getSmartRecommendations(plantName),
      scannedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods — Crop & Ornamental smart care recommendations
  // ═══════════════════════════════════════════════════════════════════════════

  static List<String> _getSmartRecommendations(String plantName) {
    final lower = plantName.toLowerCase();
    if (lower.contains('tomato') || lower.contains('solanum lycopersicum')) {
      return const [
        'Water at soil level early in the morning to keep foliage dry.',
        'Prune lower leaves that touch the soil to prevent soil-borne fungal spores.',
        'Support heavy fruit trusses with stakes or cages to keep fruits off the ground.',
        'Provide full sunlight (6-8 hours daily) and fertile, well-drained soil.',
      ];
    }
    if (lower.contains('coleus') || lower.contains('solenostemon')) {
      return const [
        'Provide bright, indirect light to maintain vivid leaf colors.',
        'Pinch off flower buds to encourage bushier foliage growth.',
        'Water regularly but avoid waterlogged soil.',
      ];
    }
    if (lower.contains('tulsi') || lower.contains('basil') || lower.contains('ocimum')) {
      return const [
        'Place in full sunlight for at least 6 hours daily.',
        'Water when the top layer of soil feels dry.',
        'Prune regularly to promote bushy growth and prevent flowering.',
      ];
    }
    if (lower.contains('rose') || lower.contains('rosa')) {
      return const [
        'Water deeply at the base, avoiding wet foliage.',
        'Prune dead blooms to encourage new flowering.',
        'Apply balanced fertilizer every 4-6 weeks during growing season.',
      ];
    }
    if (lower.contains('monstera')) {
      return const [
        'Provide bright, indirect light; avoid direct sun.',
        'Water when the top inch of soil feels dry.',
        'Wipe leaves with a damp cloth to remove dust.',
      ];
    }
    return const [
      'Water when top inch of soil feels dry.',
      'Provide bright, indirect sunlight.',
      'Ensure pot has adequate drainage holes.',
    ];
  }

  static String _getPlantDescription(
    String plantName,
    String scientificName,
    List<String>? commonNames,
    String? familyName,
  ) {
    final nameLower = plantName.toLowerCase();
    final sciLower = scientificName.toLowerCase();

    if (nameLower.contains('tomato') || sciLower.contains('solanum lycopersicum')) {
      return 'Tomato (Solanum lycopersicum) is an edible berry of the nightshade family Solanaceae. Widely cultivated globally as a culinary staple, tomato plants thrive in warm, sunny conditions and produce nutrient-rich fruits loaded with lycopene and vitamin C.';
    }
    if (nameLower.contains('coleus') || sciLower.contains('coleus') || sciLower.contains('solenostemon') || sciLower.contains('plectranthus scutellarioides')) {
      return 'Coleus is a vibrant ornamental plant prized for its strikingly colorful, variegated foliage in shades of red, green, pink, purple, and yellow. Native to Southeast Asia, it thrives in partial shade and is widely grown as a decorative houseplant and garden border.';
    }
    if (nameLower.contains('tulsi') || nameLower.contains('tulasi') || nameLower.contains('holy basil') || sciLower.contains('ocimum')) {
      return 'Tulasi (Holy Basil) is a sacred and aromatic plant in the family Lamiaceae, widely grown across India for its medicinal, spiritual, and culinary uses. It has strong antimicrobial properties and is revered in Ayurvedic medicine.';
    }
    if (nameLower.contains('monstera') || sciLower.contains('monstera')) {
      return 'Monstera Deliciosa, also known as Swiss cheese plant, is a tropical plant famed for its large, glossy, heart-shaped leaves with natural holes. Native to Central American rainforests, it is one of the most popular houseplants worldwide.';
    }
    if (nameLower.contains('snake plant') || nameLower.contains('sansevieria') || sciLower.contains('sansevieria') || sciLower.contains('dracaena trifasciata')) {
      return 'Snake plant (Mother-in-law\'s tongue) is a hardy succulent with upright sword-like leaves. It is one of the best air-purifying houseplants, known for removing toxins and releasing oxygen at night.';
    }
    if (nameLower.contains('rose') || sciLower.contains('rosa')) {
      return 'Rose is a woody perennial flowering plant of the genus Rosa in the family Rosaceae. Known for their fragrant blooms and thorny stems, roses are among the most widely cultivated ornamental plants in the world.';
    }
    if (nameLower.contains('mango') || sciLower.contains('mangifera')) {
      return 'Mango (Mangifera indica) is a tropical stone fruit tree native to South Asia. Known as the "king of fruits", it produces sweet, juicy fruits and is one of the most widely cultivated fruits in tropical regions.';
    }
    if (nameLower.contains('neem') || sciLower.contains('azadirachta')) {
      return 'Neem (Azadirachta indica) is a fast-growing evergreen tree native to the Indian subcontinent. Every part of the tree has medicinal uses, and its oil is a natural insecticide and pesticide.';
    }

    final altNames = (commonNames != null && commonNames.length > 1)
        ? ' Also commonly called: ${commonNames.sublist(1).take(3).join(', ')}.'
        : '';
    return '$plantName ($scientificName) is a botanical species known for its distinctive features and widely appreciated in gardens and homes.$altNames';
  }

  /// Preprocesses image bytes: strips EXIF, preserves aspect ratio, optimizes resolution.
  static Uint8List _stripExifIsolate(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    img.Image processed = decoded;

    const maxDimension = 1280;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(decoded, width: maxDimension);
      } else {
        processed = img.copyResize(decoded, height: maxDimension);
      }
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 88));
  }
}
