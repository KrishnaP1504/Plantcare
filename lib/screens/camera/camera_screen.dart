import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/scan_provider.dart';
import '../../services/scan_service.dart';
import '../../widgets/custom_button.dart';

/// Camera screen for scanning/identifying plants with live capture & gallery upload.
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

    if (await Permission.camera.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
      await _initializeCamera();
      return;
    }

    if (await Permission.camera.isPermanentlyDenied) {
      setState(() {
        _isPermanentlyDenied = true;
        _isCheckingPermission = false;
      });
      return;
    }

    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isPermanentlyDenied = status.isPermanentlyDenied;
      _isCheckingPermission = false;
    });

    if (status.isGranted) await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
        _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
        await _controller!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      } else {
        setState(() => _cameraError = 'No camera found on this device');
      }
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Camera error: $e');
    }
  }

  Future<void> _handleCapture() async {
    final scanProvider = context.read<ScanProvider>();
    if (scanProvider.isScanning) return;

    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not ready. Try uploading from gallery instead.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final XFile xFile = await _controller!.takePicture();
      await _processImage(File(xFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleGalleryUpload() async {
    final scanProvider = context.read<ScanProvider>();
    if (scanProvider.isScanning) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked != null) await _processImage(File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    final scanProvider = context.read<ScanProvider>();
    await scanProvider.scan(imageFile, widget.scanMode, plantId: widget.plantId);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: Color(0xFFE8F3EB), shape: BoxShape.circle),
              child: const Icon(Icons.eco_outlined, size: 36, color: Color(0xFF2C553C)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Please Click a Picture of a Plant',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1C3B30), height: 1.3),
            ),
            const SizedBox(height: 10),
            const Text(
              'We couldn\'t detect a plant in your photo. Please take a clear picture of a leaf, fruit, or flower.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF556B60), height: 1.45),
            ),
            const SizedBox(height: 24),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
          if (_isCheckingPermission)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          else if (_isPermanentlyDenied || !_hasPermission)
            _buildPermissionState(isPermanent: _isPermanentlyDenied)
          else
            _buildCameraPreview(),

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

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isCameraInitialized && _controller != null)
          Center(child: CameraPreview(_controller!))
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  _cameraError ?? 'Initializing camera...',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),

        // Viewfinder guide
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.8), width: 2.5),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                  child: Text('Align plant inside frame', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ),
        ),

        // Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Consumer<ScanProvider>(
                builder: (context, scanProvider, _) {
                  if (scanProvider.state != ScanState.error) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(scanProvider.error ?? 'Scan failed', style: AppTextStyles.bodySmall.copyWith(color: Colors.white))),
                          GestureDetector(onTap: scanProvider.clearError, child: const Icon(Icons.close, color: Colors.white, size: 18)),
                        ],
                      ),
                    ),
                  );
                },
              ),

              Consumer<ScanProvider>(
                builder: (context, scanProvider, _) {
                  final isScanning = scanProvider.isScanning;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: isScanning ? null : _handleGalleryUpload,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Icon(Icons.photo_library_rounded, color: isScanning ? Colors.white.withValues(alpha: 0.3) : Colors.white, size: 26),
                        ),
                      ),

                      // Capture button
                      GestureDetector(
                        onTap: isScanning ? null : _handleCapture,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: isScanning ? AppColors.primaryDark.withValues(alpha: 0.5) : AppColors.primaryDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
                          ),
                          child: isScanning
                              ? const Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 34),
                        ),
                      ),

                      // Flash toggle
                      GestureDetector(
                        onTap: () {
                          if (_controller != null && _controller!.value.isInitialized) {
                            final flash = _controller!.value.flashMode;
                            _controller!.setFlashMode(flash == FlashMode.off ? FlashMode.torch : FlashMode.off);
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Icon(
                            (_controller != null && _controller!.value.isInitialized && _controller!.value.flashMode == FlashMode.torch)
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
              GestureDetector(
                onTap: () {
                  if (!context.read<ScanProvider>().isScanning) _handleGalleryUpload();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_upload_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Upload from Gallery', style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _buildPermissionState({required bool isPermanent}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text(
              isPermanent ? 'Camera Access Blocked' : 'Camera Permission Required',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPermanent
                  ? 'Camera permission was permanently denied. Please enable it in settings or upload from gallery.'
                  : 'Plantcare needs camera access to scan plants, or you can upload from your gallery.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: isPermanent ? 'Open Settings' : 'Grant Permission',
              onPressed: isPermanent ? openAppSettings : _checkPermission,
            ),
            const SizedBox(height: 16),
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
