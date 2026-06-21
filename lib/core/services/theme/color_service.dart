import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/constants.dart';
import 'app_colors.dart';

/// {@template color_service}
/// Handles loading, caching, and providing app color themes
/// (light and dark) from JSON files located in the assets directory.
///
/// This service supports theme switching at runtime and logs
/// all actions for better debugging during development.
/// {@endtemplate}
final class ColorService {
  /// The current active color palette.
  static late AppColors colors;

  /// The currently active theme mode.
  static AppThemeMode currentMode = AppThemeMode.dark;

  /// Cache to store already loaded themes.
  static final Map<AppThemeMode, AppColors> _cache = {};

  /// Initializes the color theme at app startup.
  ///
  /// Loads and caches the theme JSON file only once.
  static Future<void> init({AppThemeMode mode = AppThemeMode.dark}) async {
    await _loadTheme(mode);
  }

  /// Switches between light and dark themes at runtime.
  static Future<void> switchTheme(AppThemeMode mode) async {
    if (_cache.containsKey(mode)) {
      colors = _cache[mode]!;
      currentMode = mode;
      AppLogger.info(
        "✅ Switched theme mode to ${mode.name}",
        tag: "ColorService",
      );
      return;
    }
    await _loadTheme(mode);
  }

  /// Loads and parses the theme JSON file for the given mode.
  static Future<void> _loadTheme(AppThemeMode mode) async {
    final themePath = mode == AppThemeMode.dark
        ? AppConstants.themes.dark
        : AppConstants.themes.light;
print(themePath);
    try {
      final jsonString = await rootBundle.loadString(themePath);
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      final loadedColors = AppColors.fromJson(jsonData);
      _cache[mode] = loadedColors;
      colors = loadedColors;
      currentMode = mode;

      AppLogger.success(
        "🎨 Loaded ${mode.name} theme successfully.",
        tag: "ColorService",
      );
    } catch (e, stackTrace) {
      /// Log and fallback to default theme
      AppLogger.error("❌ Failed to load $mode theme: $e", tag: "ColorService");
      debugPrint(stackTrace.toString());

      colors = const AppColors(
        primary: Color(0xFF0066FF),
        secondary: Color(0xFFFF9800),
        tertiary: Color(0xFF03A9F4),
        quaternary: Color(0xFF673AB7),
        background: Color(0xFFFFFFFF),
        surface: Color(0xFFF8F9FA),
        border: Color(0xFFE0E0E0),
        divider: Color(0xFFEEEEEE),
        error: Color(0xFFF44336),
        warning: Color(0xFFFFEB3B),
        success: Color(0xFF4CAF50),
        info: Color(0xFF2196F3),
        white: Color(0xFFFFFFFF),
        black: Color(0xFF000000),
        grey: Color(0xFF9E9E9E),
        lightGrey: Color(0xFFF5F5F5),
        darkGrey: Color(0xFF616161),
        textPrimary: Color(0xFF212121),
        textSecondary: Color(0xFF757575),
        textDisabled: Color(0xFFBDBDBD),
      );
    }
  }
}

/// Enum representing available theme modes.
enum AppThemeMode { light, dark }
