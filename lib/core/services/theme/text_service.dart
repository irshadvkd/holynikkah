import 'package:flutter/material.dart';
import 'package:holynikkah/core/services/theme/color_service.dart';

/// {@template text_service}
/// Centralized text style service.
///
/// Provides app-wide [TextStyle] based on the currently active [ColorService] theme.
/// This allows text colors to automatically adapt to light/dark mode.
/// {@endtemplate}
final class TextService {
  TextService._(); // Private constructor

  /// Current app-wide text styles
  static late TextTheme textTheme;

  /// Initializes text styles based on the current [ColorService.colors].
  static Future<void> init({AppThemeMode mode = AppThemeMode.light}) async {
    // Ensure colors are loaded
    await ColorService.init(mode: mode);

    final colors = ColorService.colors;

    textTheme = TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),

      // Titles / Subtitles
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),

      // Subtitles
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),

      // Body / Paragraphs
      bodySmall: TextStyle(fontSize: 14, color: colors.textPrimary),

      // Captions / Labels
      labelLarge: TextStyle(fontSize: 12, color: colors.textSecondary),
      labelSmall: TextStyle(fontSize: 10, color: colors.textDisabled),
    );
  }
}
