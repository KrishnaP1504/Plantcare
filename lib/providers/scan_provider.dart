import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/diagnosis_model.dart';
import '../services/scan_service.dart';

/// Scan result state.
enum ScanState { idle, scanning, success, error }

/// Scan flow state management.
///
/// Delegates I/O to [ScanService]. Manages loading/error/result states.
/// Includes debounce guard — prevents concurrent scan requests.
class ScanProvider extends ChangeNotifier {
  final ScanService _scanService;

  ScanProvider({required ScanService scanService})
      : _scanService = scanService;

  ScanState _state = ScanState.idle;
  DiagnosisModel? _diagnosis;
  String? _error;

  // ── Getters ──

  ScanState get state => _state;
  DiagnosisModel? get diagnosis => _diagnosis;
  String? get error => _error;
  bool get isNotAPlant => _error == 'NOT_A_PLANT';

  /// Whether a scan is currently in progress.
  /// Used by the capture button to prevent double-tap.
  bool get isScanning => _state == ScanState.scanning;

  // ── Actions ──

  /// Scan a plant image.
  ///
  /// [image] — the captured camera image file.
  /// [mode] — identify (unknown plant) or diagnose (health check).
  /// [plantId] — required for [ScanMode.diagnose].
  ///
  /// Double-tap safe: returns immediately if already scanning.
  Future<void> scan(
    File image,
    ScanMode mode, {
    String? plantId,
  }) async {
    // Debounce guard — prevent concurrent scan requests
    if (_state == ScanState.scanning) return;

    assert(
      mode != ScanMode.diagnose || plantId != null,
      'plantId is required for ScanMode.diagnose',
    );
    if (mode == ScanMode.diagnose && plantId == null) {
      throw ArgumentError('plantId is required when mode is ScanMode.diagnose');
    }

    _state = ScanState.scanning;
    _error = null;
    _diagnosis = null;
    notifyListeners();

    try {
      final imageBytes = await image.readAsBytes();

      final result = await _scanService.identify(
        imageBytes: imageBytes,
        mode: mode,
        plantId: plantId,
      );
      
      // Preserve local camera capture photo path
      _diagnosis = DiagnosisModel(
        id: result.id,
        plantName: result.plantName,
        scientificName: result.scientificName,
        confidence: result.confidence,
        description: result.description,
        diseases: result.diseases,
        recommendations: result.recommendations,
        imageUrl: result.imageUrl,
        imagePath: image.path,
        scannedAt: result.scannedAt,
      );
      _state = ScanState.success;
    } on NotAPlantException {
      _error = 'NOT_A_PLANT';
      _state = ScanState.error;
    } catch (e) {
      _error = e.toString();
      _state = ScanState.error;
    }

    notifyListeners();
  }

  /// Reset scan state (e.g., when navigating away or retrying).
  void reset() {
    _state = ScanState.idle;
    _diagnosis = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error and return to idle.
  void clearError() {
    _error = null;
    _state = ScanState.idle;
    notifyListeners();
  }
}
