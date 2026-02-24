import 'dart:convert';
import 'package:flutter/foundation.dart'; // Needed for debugPrint
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ⚠️ Replace with your valid API Key if needed
  static const String _apiKey = "YOUR_API_KEY_HERE"; 

  static Future<Map<String, dynamic>> identifyPlant(String base64Image) async {
    // First try with Gemini 2.5 (your preferred model).
    try {
      return await _identifyWithModel('gemini-2.5-flash', base64Image);
    } catch (e) {
      final msg = e.toString();
      debugPrint("identifyPlant error with gemini-2.5-flash: $e");

      // If the model is not found / unsupported in this SDK, transparently
      // fall back to 1.5 so the feature still works.
      if (msg.contains('NOT_FOUND') || msg.contains('404') || msg.contains('model') && msg.contains('not found')) {
        debugPrint("Falling back to gemini-1.5-flash for compatibility.");
        try {
          return await _identifyWithModel('gemini-1.5-flash', base64Image);
        } catch (e2) {
          debugPrint("Fallback model failed: $e2");
          return _getErrorData("AI error: $e2");
        }
      }

      return _getErrorData("AI error: $e");
    }
  }

  static Future<Map<String, dynamic>> searchPlant(String query) async {
    final prompt = "Give me details about '$query' plant in JSON format: { 'name': '', 'scientific_name': '', 'description': '', 'waterFrequency': 7, 'light': 'Indirect', 'temp': '18-24°C', 'difficulty': 'Easy' }";

    try {
      return await _searchWithModel('gemini-2.5-flash', prompt);
    } catch (e) {
      final msg = e.toString();
      debugPrint("searchPlant error with gemini-2.5-flash: $e");

      if (msg.contains('NOT_FOUND') || msg.contains('404') || msg.contains('model') && msg.contains('not found')) {
        debugPrint("Falling back to gemini-1.5-flash for search.");
        try {
          return await _searchWithModel('gemini-1.5-flash', prompt);
        } catch (e2) {
          debugPrint("Search fallback failed: $e2");
          return {'name': query, 'description': 'Search unavailable.'};
        }
      }

      return {'name': query, 'description': 'Search unavailable: $e'};
    }
  }

  static Future<Map<String, dynamic>> _identifyWithModel(
    String modelName,
    String base64Image,
  ) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final prompt = TextPart("""
      Identify this plant from the image. 
      Return a single JSON object with these exact keys:
      {
        "plant_name": "Common Name",
        "scientific_name": "Latin Name",
        "description": "Short description (max 2 sentences)",
        "is_healthy": true,
        "disease_name": "Name of disease or 'None' if healthy",
        "symptoms": ["Symptom 1", "Symptom 2"], 
        "treatments": ["Treatment 1", "Treatment 2"],
        "care_tips": "Watering and light advice",
        "watering_frequency": 7,
        "risk_level": 0.1
      }
      If the plant is healthy, 'symptoms' and 'treatments' should be empty arrays [].
      If no plant is found, set 'plant_name' to 'Unknown'.
    """);

    final imageParts = [
      DataPart('image/jpeg', base64Decode(base64Image)),
    ];

    final response = await model.generateContent([
      Content.multi([prompt, ...imageParts])
    ]);

    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      return _getErrorData("No response from AI");
    }

    final cleaned = _extractJson(text);

    try {
      final Map<String, dynamic> data = jsonDecode(cleaned);

      // Ensure critical lists exist
      if (data['symptoms'] == null) data['symptoms'] = [];
      if (data['treatments'] == null) data['treatments'] = [];

      return data;
    } catch (e) {
      debugPrint("JSON Parse Error: $e");
      debugPrint("Raw AI Output: $cleaned");
      return _getErrorData("Failed to read AI response.");
    }
  }

  static Future<Map<String, dynamic>> _searchWithModel(
    String modelName,
    String prompt,
  ) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      return {'name': '', 'description': 'No response from AI.'};
    }
    final cleaned = _extractJson(text);
    return jsonDecode(cleaned);
  }

  static Map<String, dynamic> _getErrorData(String message) {
    return {
      'plant_name': 'Scan error',
      'scientific_name': 'Try again',
      'description': message,
      'is_healthy': false,
      'disease_name': 'Not available',
      'symptoms': [],
      'treatments': [],
      'watering_frequency': 7,
      'risk_level': 0.0
    };
  }

  /// Try to pull a JSON object out of a text response.
  static String _extractJson(String text) {
    final trimmed = text.trim();

    // Strip markdown fences if present.
    if (trimmed.startsWith('```')) {
      final withoutFence = trimmed
          .replaceFirst(RegExp(r'^```[a-zA-Z]*'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
      return withoutFence;
    }

    // Fallback: take from first '{' to last '}' if they exist.
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return trimmed.substring(start, end + 1);
    }

    return trimmed;
  }
}
