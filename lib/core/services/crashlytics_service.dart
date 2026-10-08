import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// 🛡️ Crashlytics Service
///
/// Centralized manager for Firebase Crashlytics error reporting,
/// crash collection, user attribution, and breadcrumbs.
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  bool _isInitialized = false;

  /// Initialize Crashlytics configuration
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Enable Crashlytics collection
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Force upload any unsent crash reports immediately on launch
      await FirebaseCrashlytics.instance.sendUnsentReports();

      // Set global custom keys for debugging
      await setCustomKey('platform', Platform.operatingSystem);
      await setCustomKey('is_debug', kDebugMode);

      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Failed to initialize CrashlyticsService: $e');
    }
  }

  /// Record a Flutter framework error (e.g. build, render, layout exceptions)
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordFlutterError(
        details,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('⚠️ Error reporting Flutter error to Crashlytics: $e');
    }
  }

  /// Record unhandled or handled Dart exceptions
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('⚠️ Error reporting exception to Crashlytics: $e');
    }
  }

  /// Add a breadcrumb log to the crash report
  Future<void> log(String message) async {
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      debugPrint('⚠️ Error logging breadcrumb to Crashlytics: $e');
    }
  }

  /// Set user ID to associate crashes with a specific user
  Future<void> setUserIdentifier(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('⚠️ Error setting user identifier in Crashlytics: $e');
    }
  }

  /// Clear user identification upon logout
  Future<void> clearUserIdentifier() async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    } catch (e) {
      debugPrint('⚠️ Error clearing user identifier in Crashlytics: $e');
    }
  }

  /// Set custom key-value pairs for context (tier, screen, state, etc.)
  Future<void> setCustomKey(String key, Object value) async {
    try {
      if (value is String) {
        await FirebaseCrashlytics.instance.setCustomKey(key, value);
      } else if (value is int) {
        await FirebaseCrashlytics.instance.setCustomKey(key, value);
      } else if (value is double) {
        await FirebaseCrashlytics.instance.setCustomKey(key, value);
      } else if (value is bool) {
        await FirebaseCrashlytics.instance.setCustomKey(key, value);
      } else {
        await FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
      }
    } catch (e) {
      debugPrint('⚠️ Error setting custom key ($key) in Crashlytics: $e');
    }
  }
}
