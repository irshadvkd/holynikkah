import 'package:flutter/material.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized Service for Handling System & App Permissions
class AppPermissionService {
  AppPermissionService._();

  static final AppPermissionService instance = AppPermissionService._();
  static const String _tag = 'AppPermissionService';

  /// Check if notification permission is currently granted
  Future<bool> isNotificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission (handles Android 13+ and iOS)
  Future<bool> requestNotificationPermission({BuildContext? context}) async {
    AppLogger.info('Requesting notification permission...', tag: _tag);

    final status = await Permission.notification.status;

    if (status.isGranted) {
      AppLogger.info('Notification permission already granted', tag: _tag);
      return true;
    }

    if (status.isPermanentlyDenied) {
      AppLogger.warning('Notification permission permanently denied', tag: _tag);
      if (context != null && context.mounted) {
        _showSettingsDialog(
          context,
          title: 'Notification Permission Needed',
          message:
              'Notifications are disabled. Please enable them in system settings to receive contact requests, visitor alerts, and updates.',
        );
      }
      return false;
    }

    final result = await Permission.notification.request();
    AppLogger.info('Notification permission request result: $result', tag: _tag);

    if (result.isGranted) {
      return true;
    } else if (result.isPermanentlyDenied && context != null && context.mounted) {
      _showSettingsDialog(
        context,
        title: 'Notification Permission Needed',
        message:
            'Notifications are disabled. Please enable them in system settings to receive contact requests, visitor alerts, and updates.',
      );
    }

    return false;
  }

  /// Request Camera Permission (for profile photo capture)
  Future<bool> requestCameraPermission({BuildContext? context}) async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied && context != null && context.mounted) {
      _showSettingsDialog(
        context,
        title: 'Camera Permission Needed',
        message:
            'Camera access is required to take profile photos. Please enable it in Settings.',
      );
    }
    return status.isGranted;
  }

  /// Request Photos / Media Library Permission
  Future<bool> requestPhotosPermission({BuildContext? context}) async {
    final status = await Permission.photos.request();
    if (status.isPermanentlyDenied && context != null && context.mounted) {
      _showSettingsDialog(
        context,
        title: 'Photos Access Needed',
        message:
            'Photo library access is required to select profile images. Please enable it in Settings.',
      );
    }
    return status.isGranted;
  }

  /// Open System App Settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Settings prompt dialog matching HolyNikah's luxury styling
  void _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101D33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.primary, width: 1),
        ),
        title: Text(
          title,
          style: AppTypography.cormorantGaramond(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: AppTypography.marcellus(
            color: AppColors.white.withOpacity(0.85),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.marcellus(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
