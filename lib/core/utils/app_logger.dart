import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:holynikkah/core/services/crashlytics_service.dart';
import 'package:holynikkah/core/utils/constants.dart';

/// 🧭 Global logger utility for consistent and secure logging across the app.
///
/// Features:
/// - Info, Warning, Error, Success, Debug, and Fatal log levels.
/// - Allows verbose logs in release mode if [AppConstants.enableReleaseLogs] is true.
/// - Optional secure redaction of sensitive values.
/// - Includes timestamps and tag support for easy filtering.
/// - Automatically sends logs and errors to Firebase Crashlytics.
class AppLogger {
  AppLogger._(); // 🚫 Private constructor to prevent instantiation

  static bool get _shouldLog => kDebugMode || AppConstants.enableReleaseLogs;

  static void _writeLog(
    String message, {
    String tag = '',
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      message,
      name: tag,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );

    // In release mode, dev.log might not output to standard stdout/terminal.
    // Use print to ensure logs are visible in console/logcat when enabled.
    if (!kDebugMode && AppConstants.enableReleaseLogs) {
      final prefix = tag.isNotEmpty ? '[$tag] ' : '';
      // ignore: avoid_print
      print('$prefix$message');
      if (error != null) {
        // ignore: avoid_print
        print('$prefix Error: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('$prefix StackTrace:\n$stackTrace');
      }
    }
  }

  /// 🟢 Logs general informational messages.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.info('User logged in successfully', tag: 'Auth');
  /// ```
  static void info(String message, {String tag = 'INFO'}) {
    if (_shouldLog) {
      _writeLog('💬 $message', tag: tag);
    }
    CrashlyticsService.instance.log('💬 [$tag] $message');
  }

  /// 🟡 Logs warnings for recoverable issues.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.warning('API response delayed', tag: 'Network');
  /// ```
  static void warning(String message, {String tag = 'WARNING'}) {
    if (_shouldLog) {
      _writeLog('⚠️ $message', tag: tag);
    }
    CrashlyticsService.instance.log('⚠️ [$tag] $message');
  }

  /// 🔴 Logs errors — displayed in both debug and release builds, and sent to Crashlytics.
  ///
  /// Supports optional error object and stack trace.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await api.fetchData();
  /// } catch (e, s) {
  ///   AppLogger.error('Failed to fetch data', error: e, stackTrace: s);
  /// }
  /// ```
  static void error(
    String message, {
    String tag = 'ERROR',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _writeLog(
      '❌ $message',
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    if (error != null) {
      CrashlyticsService.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: '[$tag] $message',
        fatal: false,
      );
    } else {
      CrashlyticsService.instance.log('❌ [$tag] $message');
    }
  }

  /// ✅ Logs success messages — useful for completed actions.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.success('Theme applied successfully', tag: 'ThemeService');
  /// ```
  static void success(String message, {String tag = 'SUCCESS'}) {
    if (_shouldLog) {
      _writeLog('✅ $message', tag: tag);
    }
    CrashlyticsService.instance.log('✅ [$tag] $message');
  }

  /// 🐞 Debug level — for verbose internal debugging.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.debug('Widget rebuild triggered', tag: 'UI');
  /// ```
  static void debug(String message, {String tag = 'DEBUG'}) {
    if (_shouldLog) {
      _writeLog('🐛 $message', tag: tag);
    }
  }

  /// 💀 Fatal / critical log — for unrecoverable errors.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.fatal('Database initialization failed!', tag: 'DB');
  /// ```
  static void fatal(
    String message, {
    String tag = 'FATAL',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _writeLog(
      '💀 $message',
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    CrashlyticsService.instance.recordError(
      error ?? Exception(message),
      stackTrace ?? StackTrace.current,
      reason: '[$tag] $message',
      fatal: true,
    );
  }

  /// 🔒 Securely redacts sensitive information.
  ///
  /// Example:
  /// ```dart
  /// final safeToken = AppLogger.secure(apiToken);
  /// AppLogger.info('Using token: $safeToken');
  /// ```
  static String secure(String value, {int showLast = 3}) {
    if (value.isEmpty) return value;
    final visibleLength = showLast > value.length ? value.length : showLast;
    return '*' * (value.length - visibleLength) + value.substring(value.length - visibleLength);
  }
}
