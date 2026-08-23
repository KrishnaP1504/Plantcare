import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/scan_provider.dart';
import '../../services/permission_service.dart';
import '../../services/scan_service.dart';
import '../../widgets/custom_button.dart';

/// Camera screen for scanning/identifying plants.
///
/// Features:
/// - Real-time camera preview using [CameraController]
/// - Real photo capture via `controller.takePicture()`
/// - Handles 3 permission states: granted, denied, permanently denied
/// - Debounce guard & loading overlay during scan
class CameraScreen extends StatefulWidget {
  final ScanMode scanMode;
  final String? plantId;

  const CameraScreen({
    super.key,
    this.scanMode = ScanMode.identify,
    this.plantId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final PermissionService _permissionService = PermissionService();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _hasPermission = false;
  bool _isPermanentlyDenied = false;
  bool _isCheckingPermission = true;
  bool _isCameraInitialized = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() => _isCheckingPermission = true);

    final isGranted = await _permissionService.isCameraGranted();
    if (isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
      await _initializeCamera();
      return;
    }

    final isPermanentlyDenied =
        await _permissionService.isCameraPermanentlyDenied();
    if (isPermanentlyDenied) {
      setState(() {
        _isPermanentlyDenied = true;
        _isCheckingPermission = false;
      });
      return;
    }

    // Request permission
    final status = await _permissionService.requestCamera();
    setState(() {
      _hasPermission = status.isGranted;
      _isPermanentlyDenied = status.isPermanentlyDenied;
      _isCheckingPermission = false;
    });

    if (status.isGranted) {
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
        _controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        setState(() {
          _cameraError = 'No camera found on this device';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _handleCapture() async {
    final scanProvider = context.read<ScanProvider>();
    if (scanProvider.isScanning) return; // debounce guard

    File imageFile;
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final XFile xFile = await _controller!.takePicture();
        imageFile = File(xFile.path);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to take picture: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    } else {
      // Fallback for emulator / environments without active camera hardware
      final tempDir = Directory.systemTemp;
      imageFile = File(
          '${tempDir.path}/captured_plant_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageFile.writeAsBytes(Uint8List.fromList(List.generate(100, (i) => i)));
    }

    await scanProvider.scan(
      imageFile,
      widget.scanMode,
      plantId: widget.plantId,
    );

    if (mounted) {
      if (scanProvider.state == ScanState.success) {
        context.push('/scan-result');
      } else if (scanProvider.isNotAPlant) {
        _showNotAPlantDialog(context, scanProvider);
      }
    }
  }

  void _showNotAPlantDialog(BuildContext context, ScanProvider scanProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F3EB),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🌿',
                  style: TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Please Click a Picture of a Plant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C3B30),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle / Body
            const Text(
              'We couldn\'t detect a plant in your photo. Please take a clear picture of a plant or leaf.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF556B60),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Try Again Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  scanProvider.clearError();
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.scanMode == ScanMode.identify
              ? 'Scan Plant'
              : 'Plant Diagnostics',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
      ),
      body: _isCheckingPermission
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            )
          : _isPermanentlyDenied
              ? _buildPermanentlyDeniedState()
              : !_hasPermission
                  ? _buildDeniedState()
                  : _buildCameraView(),
    );
  }

  /// Real-time camera preview with capture button.
  Widget _buildCameraView() {
    return Stack(
      children: [
        // Live camera preview or fallback viewfinder
        if (_isCameraInitialized && _controller != null && _controller!.value.isInitialized)
          SizedBox.expand(
            child: CameraPreview(_controller!),
          )
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_cameraError != null) ...[
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _cameraError!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: AppColors.primaryLight),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Scanning overlay viewfinder border
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.8),
                width: 2.5,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Align plant inside frame',
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom capture area
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Error message
              Consumer<ScanProvider>(
                builder: (context, scanProvider, _) {
                  if (scanProvider.state == ScanState.error) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                scanProvider.error ?? 'Scan failed',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => scanProvider.clearError(),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Capture button
              Consumer<ScanProvider>(
                builder: (context, scanProvider, _) {
                  final isScanning = scanProvider.isScanning;
                  return GestureDetector(
                    onTap: isScanning ? null : _handleCapture,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isScanning
                            ? AppColors.primaryDark.withValues(alpha: 0.5)
                            : AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isScanning
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 34,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Permission denied state.
  Widget _buildDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Plantcare needs camera access to scan and identify your plants.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Grant Permission',
              onPressed: _checkPermission,
            ),
          ],
        ),
      ),
    );
  }

  /// Permanently denied state.
  Widget _buildPermanentlyDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Access Blocked',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Camera permission was permanently denied. '
              'Please enable it in your device settings.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Open Settings',
              onPressed: () async {
                await _permissionService.openSettings();
              },
            ),
          ],
        ),
      ),
    );
  }
}
