import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/services/theme/color_service.dart';

/// {@template text_service}
/// Centralized text style service.
///
/// Provides app-wide [GoogleFonts.inter] based on the currently active [ColorService] theme.
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
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),

      // Titles / Subtitles
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),

      // Subtitles
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),

      // Body / Paragraphs
      bodySmall: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary),

      // Captions / Labels
      labelLarge: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 10, color: colors.textDisabled),
    );
  }
}
