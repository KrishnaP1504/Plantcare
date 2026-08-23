import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../services/plant_service.dart';

/// Plant collection state management.
///
/// Delegates all I/O to [PlantService].
class PlantProvider extends ChangeNotifier {
  final PlantService _plantService;

  PlantProvider({required PlantService plantService})
      : _plantService = plantService;

  List<PlantModel> _plants = [];
  PlantModel? _featuredPlant;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──

  List<PlantModel> get plants => List.unmodifiable(_plants);
  PlantModel? get featuredPlant => _featuredPlant;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPlants => _plants.isNotEmpty;

  // ── Actions ──

  /// Load plants from the service.
  Future<void> loadPlants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plants = await _plantService.getMyPlants();
      _featuredPlant = _plants.isNotEmpty ? _plants.first : null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  final List<PlantModel> _globalSearchCache = [];

  /// Add a temporary global search plant to the cache.
  void addGlobalSearchPlant(PlantModel plant) {
    _globalSearchCache.removeWhere((p) => p.id == plant.id);
    _globalSearchCache.add(plant);
    notifyListeners();
  }

  /// Get a plant by ID from loaded garden plants or global search cache.
  PlantModel? getPlantById(String id) {
    try {
      return _plants.firstWhere((p) => p.id == id);
    } catch (_) {
      try {
        return _globalSearchCache.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  /// Add a plant to the garden.
  Future<bool> addPlant(PlantModel plant) async {
    _isLoading = true;
    notifyListeners();

    try {
      final added = await _plantService.addToGarden(plant);
      _plants.add(added);
      _featuredPlant ??= added;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a plant from the garden.
  Future<bool> removePlant(String plantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _plantService.removeFromGarden(plantId);
      _plants.removeWhere((p) => p.id == plantId);
      if (_featuredPlant?.id == plantId) {
        _featuredPlant = _plants.isNotEmpty ? _plants.first : null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
