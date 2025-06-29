import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing storage and other permissions required for offline functionality.
///
/// Handles requesting, checking, and managing permissions needed for
/// downloading and storing music files locally.
class PermissionService extends GetxController {
  /// Current storage permission status.
  final Rx<PermissionStatus> _storagePermissionStatus = PermissionStatus.denied.obs;

  /// Gets the current storage permission status.
  PermissionStatus get storagePermissionStatus => _storagePermissionStatus.value;

  /// Stream of storage permission status changes.
  Stream<PermissionStatus> get storagePermissionStream => _storagePermissionStatus.stream;

  /// Checks if storage permission is granted.
  bool get hasStoragePermission => 
      _storagePermissionStatus.value == PermissionStatus.granted;

  /// Initializes the permission service and checks current permissions.
  Future<void> initialize() async {
    await _checkCurrentPermissions();
  }

  /// Requests storage permission for downloading files.
  Future<PermissionStatus> requestStoragePermission() async {
    try {
      PermissionStatus status;
      
      // Check platform and request appropriate permission
      if (GetPlatform.isAndroid) {
        // For Android, we need storage permission
        status = await Permission.storage.request();
        
        // On Android 10+, also check manage external storage if needed
        if (status.isDenied || status.isPermanentlyDenied) {
          status = await Permission.manageExternalStorage.request();
        }
      } else if (GetPlatform.isIOS) {
        // iOS doesn't require explicit storage permission for app documents
        // But we might need photo library permission for certain features
        status = PermissionStatus.granted;
      } else {
        // For other platforms, grant by default
        status = PermissionStatus.granted;
      }

      _storagePermissionStatus.value = status;
      return status;
    } catch (e) {
      _storagePermissionStatus.value = PermissionStatus.denied;
      return PermissionStatus.denied;
    }
  }

  /// Checks if the user should be shown permission rationale.
  Future<bool> shouldShowStoragePermissionRationale() async {
    if (GetPlatform.isAndroid) {
      return await Permission.storage.shouldShowRequestRationale;
    }
    return false;
  }

  /// Opens app settings for the user to manually grant permissions.
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Requests notification permission (for download completion notifications).
  Future<PermissionStatus> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  /// Checks if notification permission is granted.
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status == PermissionStatus.granted;
  }

  /// Checks all current permissions and updates status.
  Future<void> _checkCurrentPermissions() async {
    try {
      PermissionStatus storageStatus;
      
      if (GetPlatform.isAndroid) {
        storageStatus = await Permission.storage.status;
        
        // Check manage external storage for newer Android versions
        if (storageStatus.isDenied) {
          final manageStatus = await Permission.manageExternalStorage.status;
          if (manageStatus.isGranted) {
            storageStatus = manageStatus;
          }
        }
      } else {
        // For iOS and other platforms
        storageStatus = PermissionStatus.granted;
      }

      _storagePermissionStatus.value = storageStatus;
    } catch (e) {
      _storagePermissionStatus.value = PermissionStatus.denied;
    }
  }

  /// Checks if all required permissions for offline functionality are granted.
  Future<bool> hasAllRequiredPermissions() async {
    await _checkCurrentPermissions();
    return hasStoragePermission;
  }

  /// Requests all required permissions for offline functionality.
  Future<Map<String, PermissionStatus>> requestAllPermissions() async {
    final results = <String, PermissionStatus>{};
    
    // Request storage permission
    results['storage'] = await requestStoragePermission();
    
    // Request notification permission (optional)
    results['notification'] = await requestNotificationPermission();
    
    return results;
  }

  /// Shows a dialog explaining why permissions are needed.
  Future<void> showPermissionRationale({
    required String title,
    required String message,
    VoidCallback? onGrantPressed,
    VoidCallback? onDenyPressed,
  }) async {
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              onDenyPressed?.call();
            },
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              onGrantPressed?.call();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Shows permission denied dialog with option to open settings.
  Future<void> showPermissionDeniedDialog({
    required String title,
    required String message,
  }) async {
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'You can enable permissions in app settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Gets a user-friendly description of the permission status.
  String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.limited:
        return 'Limited permission granted';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied';
      case PermissionStatus.provisional:
        return 'Provisional permission granted';
    }
  }
}