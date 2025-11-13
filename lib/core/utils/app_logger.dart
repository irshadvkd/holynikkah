import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// 🧭 Global logger utility for consistent and secure logging across the app.
///
/// Features:
/// - Info, Warning, Error, Success, Debug, and Fatal log levels.
/// - Disabled verbose logs in release builds for security/performance.
/// - Optional secure redaction of sensitive values.
/// - Includes timestamps and tag support for easy filtering.
class AppLogger {
  AppLogger._(); // 🚫 Private constructor to prevent instantiation

  /// 🟢 Logs general informational messages.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.info('User logged in successfully', tag: 'Auth');
  /// ```
  static void info(String message, {String tag = 'INFO'}) {
    if (kDebugMode) dev.log('💬 $message', name: tag, time: DateTime.now());
  }

  /// 🟡 Logs warnings for recoverable issues.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.warning('API response delayed', tag: 'Network');
  /// ```
  static void warning(String message, {String tag = 'WARNING'}) {
    if (kDebugMode) dev.log('⚠️ $message', name: tag, time: DateTime.now());
  }

  /// 🔴 Logs errors — displayed even in production builds.
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
    dev.log(
      '❌ $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  /// ✅ Logs success messages — useful for completed actions.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.success('Theme applied successfully', tag: 'ThemeService');
  /// ```
  static void success(String message, {String tag = 'SUCCESS'}) {
    if (kDebugMode) dev.log('✅ $message', name: tag, time: DateTime.now());
  }

  /// 🐞 Debug level — for verbose internal debugging.
  ///
  /// Only logs in debug mode.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.debug('Widget rebuild triggered', tag: 'UI');
  /// ```
  static void debug(String message, {String tag = 'DEBUG'}) {
    if (kDebugMode) dev.log('🐛 $message', name: tag, time: DateTime.now());
  }

  /// 💀 Fatal / critical log — for unrecoverable errors.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.fatal('Database initialization failed!', tag: 'DB');
  /// ```
  static void fatal(String message, {String tag = 'FATAL', Object? error, StackTrace? stackTrace}) {
    dev.log(
      '💀 $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
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
