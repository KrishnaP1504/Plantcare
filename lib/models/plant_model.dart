/// Represents a plant in the user's garden or from identification.
class PlantModel {
  final String id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? imageUrl;
  final String? imagePath;
  final double? confidence;
  final List<String> symptoms;
  final List<String> diseases;
  final List<String> recommendations;
  final List<String> treatments;
  final DateTime? plantedDate;
  final double? temperature;
  final double? humidity;
  final bool needsWater;
  final bool isInGarden;

  const PlantModel({
    required this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.imageUrl,
    this.imagePath,
    this.confidence,
    this.symptoms = const [],
    this.diseases = const [],
    this.recommendations = const [],
    this.treatments = const [],
    this.plantedDate,
    this.temperature,
    this.humidity,
    this.needsWater = false,
    this.isInGarden = false,
  });

  /// Days since the plant was added to the garden.
  int get daysSincePlanted {
    if (plantedDate == null) return 0;
    return DateTime.now().difference(plantedDate!).inDays;
  }

  /// Formatted duration text (e.g. "Today", "Yesterday", "12 days ago planted").
  String get formattedPlantedAgo {
    final days = daysSincePlanted;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago planted';
  }

  /// Formatted short duration label (e.g. "Today", "Yesterday", "12 days").
  String get formattedDaysShort {
    final days = daysSincePlanted;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days';
  }

  PlantModel copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? description,
    String? imageUrl,
    String? imagePath,
    double? confidence,
    List<String>? symptoms,
    List<String>? diseases,
    List<String>? recommendations,
    List<String>? treatments,
    DateTime? plantedDate,
    double? temperature,
    double? humidity,
    bool? needsWater,
    bool? isInGarden,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      confidence: confidence ?? this.confidence,
      symptoms: symptoms ?? this.symptoms,
      diseases: diseases ?? this.diseases,
      recommendations: recommendations ?? this.recommendations,
      treatments: treatments ?? this.treatments,
      plantedDate: plantedDate ?? this.plantedDate,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      needsWater: needsWater ?? this.needsWater,
      isInGarden: isInGarden ?? this.isInGarden,
    );
  }

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      scientificName: json['scientific_name'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      imagePath: json['image_path'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      diseases: (json['diseases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      treatments: (json['treatments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      plantedDate: json['planted_date'] != null
          ? DateTime.parse(json['planted_date'] as String)
          : null,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      needsWater: json['needs_water'] as bool? ?? false,
      isInGarden: json['is_in_garden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'description': description,
      'image_url': imageUrl,
      'image_path': imagePath,
      'confidence': confidence,
      'symptoms': symptoms,
      'diseases': diseases,
      'recommendations': recommendations,
      'treatments': treatments,
      'planted_date': plantedDate?.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'needs_water': needsWater,
      'is_in_garden': isInGarden,
    };
  }
}
