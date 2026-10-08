import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:screen_protector/screen_protector.dart';

/// 🛡️ Service to manage screen capture, recording, and screenshot protection
/// based on Firebase Remote Config key `enable_screen_security`.
class ScreenSecurityService {
  ScreenSecurityService._();

  static final ScreenSecurityService instance = ScreenSecurityService._();

  static const String _screenSecurityKey = 'enable_screen_security';

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _isProtectionActive = false;

  bool get isProtectionActive => _isProtectionActive;

  /// Initializes Remote Config, sets defaults, fetches latest config,
  /// and applies screen security according to `enable_screen_security`.
  Future<void> init() async {
    try {
      // 1. Set Remote Config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0) // Fast updates during debug/testing
              : const Duration(hours: 1),
        ),
      );

      // 2. Set default values
      await _remoteConfig.setDefaults({
        _screenSecurityKey: false,
      });

      // 3. Fetch and activate
      await _remoteConfig.fetchAndActivate();

      // 4. Apply current setting
      final isEnabled = _remoteConfig.getBool(_screenSecurityKey);
      AppLogger.info(
        'Remote Config "$_screenSecurityKey" = $isEnabled',
        tag: 'ScreenSecurity',
      );
      await applySecurity(isEnabled);

      // 5. Listen for real-time config updates (Firebase Remote Config real-time updates)
      _remoteConfig.onConfigUpdated.listen((event) async {
        if (event.updatedKeys.contains(_screenSecurityKey)) {
          await _remoteConfig.activate();
          final updatedValue = _remoteConfig.getBool(_screenSecurityKey);
          AppLogger.info(
            'Remote Config updated "$_screenSecurityKey" = $updatedValue',
            tag: 'ScreenSecurity',
          );
          await applySecurity(updatedValue);
        }
      });
    } catch (e, stack) {
      AppLogger.error(
        'Error initializing ScreenSecurityService: $e',
        tag: 'ScreenSecurity',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Enables or disables screenshot & screen recording protection
  Future<void> applySecurity(bool enable) async {
    try {
      if (kIsWeb) return;

      if (enable) {
        // Prevent screenshot & screen recording
        await ScreenProtector.preventScreenshotOn();
        if (Platform.isIOS) {
          await ScreenProtector.protectDataLeakageWithBlur();
        }
        _isProtectionActive = true;
        AppLogger.success(
          'Screen protection ENABLED (Screenshot & screen recording prevented)',
          tag: 'ScreenSecurity',
        );
      } else {
        // Allow screenshot & screen recording
        await ScreenProtector.preventScreenshotOff();
        if (Platform.isIOS) {
          await ScreenProtector.protectDataLeakageWithBlurOff();
        }
        _isProtectionActive = false;
        AppLogger.info(
          'Screen protection DISABLED (Screenshot & screen recording allowed)',
          tag: 'ScreenSecurity',
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to apply screen security: $e',
        tag: 'ScreenSecurity',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
