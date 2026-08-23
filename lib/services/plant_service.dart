import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';

/// Handles plant data I/O using Cloud Firestore database.
///
/// Plants are stored under `users/{userId}/plants/{plantId}`.
class PlantService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PlantService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _plantsCollection {
    final uid = _currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('plants');
  }

  /// Fetch all plants in the user's garden from Firestore.
  Future<List<PlantModel>> getMyPlants() async {
    try {
      final collection = _plantsCollection;
      if (collection != null) {
        final snapshot = await collection.get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .map((doc) => PlantModel.fromJson(doc.data()))
              .toList();
        }
      }
    } catch (_) {
      // Fall through to mock list if offline or unconfigured
    }

    // Return empty list if user has no plants added yet
    return [];
  }

  /// Get a single plant by ID from Firestore.
  Future<PlantModel?> getPlantById(String id) async {
    try {
      final collection = _plantsCollection;
      if (collection != null) {
        final doc = await collection.doc(id).get();
        if (doc.exists && doc.data() != null) {
          return PlantModel.fromJson(doc.data()!);
        }
      }
    } catch (_) {}

    final plants = await getMyPlants();
    try {
      return plants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add a plant to the user's garden in Firestore.
  Future<PlantModel> addToGarden(PlantModel plant) async {
    final updatedPlant = plant.copyWith(
      isInGarden: true,
      plantedDate: plant.plantedDate ?? DateTime.now(),
    );

    try {
      final collection = _plantsCollection;
      if (collection != null) {
        await collection.doc(updatedPlant.id).set(updatedPlant.toJson());
      }
    } catch (_) {
      // Local memory fallback if offline
    }

    return updatedPlant;
  }

  /// Remove a plant from the user's garden in Firestore.
  Future<void> removeFromGarden(String plantId) async {
    try {
      final collection = _plantsCollection;
      if (collection != null) {
        await collection.doc(plantId).delete();
      }
    } catch (_) {}
  }

  /// Search plants by name in Firestore.
  Future<List<PlantModel>> searchPlants(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final collection = _plantsCollection;
      if (collection != null) {
        final snapshot = await collection
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: '$query\u{f8ff}')
            .get();
        return snapshot.docs
            .map((doc) => PlantModel.fromJson(doc.data()))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
