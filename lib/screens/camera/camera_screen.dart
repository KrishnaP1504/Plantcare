import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
/// - Upload from gallery via [ImagePicker]
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
  final ImagePicker _imagePicker = ImagePicker();
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

  /// Handle camera capture
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

    await _processImage(imageFile);
  }

  /// Handle upload from gallery
  Future<void> _handleGalleryUpload() async {
    final scanProvider = context.read<ScanProvider>();
    if (scanProvider.isScanning) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile == null) return; // User cancelled

      final imageFile = File(pickedFile.path);
      await _processImage(imageFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Process image file through scan provider
  Future<void> _processImage(File imageFile) async {
    final scanProvider = context.read<ScanProvider>();

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
                child: Icon(
                  Icons.eco_outlined,
                  size: 36,
                  color: Color(0xFF2C553C),
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
              'We couldn\'t detect a plant in your photo. Please take a clear picture of a plant, leaf, flower, or fruit.',
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
                    borderRadius: BorderRadius.circular(16),
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Body content
          if (_isCheckingPermission)
            _buildLoadingState()
          else if (_isPermanentlyDenied)
            _buildPermanentlyDeniedState()
          else if (!_hasPermission)
            _buildDeniedState()
          else
            _buildCameraPreview(),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        if (_isCameraInitialized && _controller != null)
          Center(
            child: CameraPreview(_controller!),
          )
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_cameraError != null) ...[
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _cameraError!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: Colors.white),
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

        // Bottom capture area with Gallery Upload button
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

              // Capture button + Gallery upload button row
              Consumer<ScanProvider>(
                builder: (context, scanProvider, _) {
                  final isScanning = scanProvider.isScanning;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gallery Upload Button (left)
                      GestureDetector(
                        onTap: isScanning ? null : _handleGalleryUpload,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: isScanning
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white,
                            size: 26,
                          ),
                        ),
                      ),

                      // Capture Button (center)
                      GestureDetector(
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
                      ),

                      // Flash toggle (right)
                      GestureDetector(
                        onTap: () {
                          if (_controller != null && _controller!.value.isInitialized) {
                            final currentFlash = _controller!.value.flashMode;
                            _controller!.setFlashMode(
                              currentFlash == FlashMode.off ? FlashMode.torch : FlashMode.off,
                            );
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            (_controller != null &&
                                    _controller!.value.isInitialized &&
                                    _controller!.value.flashMode == FlashMode.torch)
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // "Upload from Gallery" text button
              GestureDetector(
                onTap: () {
                  final scanProvider = context.read<ScanProvider>();
                  if (!scanProvider.isScanning) _handleGalleryUpload();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_upload_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Upload from Gallery',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 16),
            // Gallery upload alternative when camera is denied
            CustomButton(
              text: 'Upload from Gallery Instead',
              variant: CustomButtonVariant.outlined,
              onPressed: _handleGalleryUpload,
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
            const SizedBox(height: 16),
            // Gallery upload alternative when camera is blocked
            CustomButton(
              text: 'Upload from Gallery Instead',
              variant: CustomButtonVariant.outlined,
              onPressed: _handleGalleryUpload,
            ),
          ],
        ),
      ),
    );
  }
}
