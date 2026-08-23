/// Result of a plant scan/diagnosis from the identification API.
class DiagnosisModel {
  final String id;
  final String plantName;
  final String? scientificName;
  final double confidence;
  final String? description;
  final List<DiseaseResult> diseases;
  final List<String> recommendations;
  final String? imageUrl;
  final String? imagePath;
  final DateTime scannedAt;

  const DiagnosisModel({
    required this.id,
    required this.plantName,
    this.scientificName,
    required this.confidence,
    this.description,
    this.diseases = const [],
    this.recommendations = const [],
    this.imageUrl,
    this.imagePath,
    required this.scannedAt,
  });

  /// Whether this is a healthy plant (no diseases detected).
  bool get isHealthy => diseases.isEmpty || diseases.every((d) => d.probability < 0.1);

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'] as String,
      plantName: json['plant_name'] as String,
      scientificName: json['scientific_name'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String?,
      diseases: (json['diseases'] as List<dynamic>?)
              ?.map((e) => DiseaseResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imageUrl: json['image_url'] as String?,
      imagePath: json['image_path'] as String?,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_name': plantName,
      'scientific_name': scientificName,
      'confidence': confidence,
      'description': description,
      'diseases': diseases.map((d) => d.toJson()).toList(),
      'recommendations': recommendations,
      'image_url': imageUrl,
      'image_path': imagePath,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }
}

/// A single disease detected during a scan.
class DiseaseResult {
  final String name;
  final double probability;
  final String? description;
  final List<String> treatments;

  const DiseaseResult({
    required this.name,
    required this.probability,
    this.description,
    this.treatments = const [],
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      name: json['name'] as String,
      probability: (json['probability'] as num).toDouble(),
      description: json['description'] as String?,
      treatments: (json['treatments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'probability': probability,
      'description': description,
      'treatments': treatments,
    };
  }
}
