import 'package:flutter/material.dart';

/// {@template app_colors}
/// A model that represents a full set of color values used throughout the app.
///
/// Each color is parsed from a JSON configuration file and converted into
/// a strongly typed [Color] for reliable, compile-time usage.
/// {@endtemplate}
final class AppColors {
  // 🔷 Brand Colors
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;

  // 🩶 Base Backgrounds
  final Color background;
  final Color surface;

  // 📏 Borders & Dividers
  final Color border;
  final Color divider;

  // ⚠️ Alerts & Status
  final Color error;
  final Color warning;
  final Color success;
  final Color info;

  // ⚪ Neutrals
  final Color white;
  final Color black;
  final Color grey;
  final Color lightGrey;
  final Color darkGrey;

  // 📝 Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  /// Creates a complete [AppColors] instance.
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
    required this.background,
    required this.surface,
    required this.border,
    required this.divider,
    required this.error,
    required this.warning,
    required this.success,
    required this.info,
    required this.white,
    required this.black,
    required this.grey,
    required this.lightGrey,
    required this.darkGrey,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
  });

  /// Factory to parse color values from a JSON map.
  factory AppColors.fromJson(Map<String, dynamic> json) {
    Color c(String key) => _fromHex(json[key] ?? "#000000");
    return AppColors(
      primary: c("primary"),
      secondary: c("secondary"),
      tertiary: c("tertiary"),
      quaternary: c("quaternary"),
      background: c("background"),
      surface: c("surface"),
      border: c("border"),
      divider: c("divider"),
      error: c("error"),
      warning: c("warning"),
      success: c("success"),
      info: c("info"),
      white: c("white"),
      black: c("black"),
      grey: c("grey"),
      lightGrey: c("light_grey"),
      darkGrey: c("dark_grey"),
      textPrimary: c("text_primary"),
      textSecondary: c("text_secondary"),
      textDisabled: c("text_disabled"),
    );
  }

  /// Converts hex color string like `#RRGGBB` or `#AARRGGBB` into [Color].
  static Color _fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
