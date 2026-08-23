import 'package:permission_handler/permission_handler.dart' as ph;

/// Handles runtime permission requests.
///
/// The camera package does not request permissions itself.
/// This service + platform manifest entries (AndroidManifest.xml, Info.plist)
/// are both required for camera access.
class PermissionService {
  /// Request camera permission. Returns the resulting status.
  Future<ph.PermissionStatus> requestCamera() async {
    return await ph.Permission.camera.request();
  }

  /// Check if camera permission is currently granted.
  Future<bool> isCameraGranted() async {
    return await ph.Permission.camera.isGranted;
  }

  /// Check if camera permission is permanently denied.
  /// User must go to OS settings to grant it.
  Future<bool> isCameraPermanentlyDenied() async {
    return await ph.Permission.camera.isPermanentlyDenied;
  }

  /// Open the OS app settings page so the user can manually grant permissions.
  Future<bool> openSettings() async {
    return await ph.openAppSettings();
  }
}
