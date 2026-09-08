import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized app color definitions
class AppColors {
  // Backgrounds
  static const Color appBlack = Color(0xFF000000);
  static const Color appBlackSoft = Color(0xFF0A0A0A);
  static const Color appBlackElevated = Color(0xFF111111);
  static const Color appSurfaceDark = Color(0xFF1A1A1A);
  static const Color appSurfaceMedium = Color(0xFF222222);
  static const Color appSurfaceLight = Color(0xFF2C2C2C);

  // Whites & Text
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color whiteSoft = Color(0xFFEDEDED);
  static const Color whiteMuted = Color(0xFFCFCFCF);
  static const Color dividerGrey = Color(0xFF3A3A3A);
  static const Color iconGrey = Color(0xFF9A9A9A);

  // Brand Yellow
  static const Color brandYellow = Color(0xFFFAC60C);
  static const Color brandYellowSoft = Color(0xFFFAC586);
  static const Color brandYellowDark = Color(0xFFD9A800);
  static const Color brandYellowShadow = Color(0xFF8A6A00);

  // Inputs
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color inputText = Color(0xFF000000);
  static const Color inputHint = Color(0xFF7A7A7A);
  static const Color inputBorder = Color(0xFFE0E0E0);

  // Cards
  static const Color cardBackground = Color(0xFF2A2A2A);
  static const Color cardHighlight = Color(0xFF333333);
  static const Color cardBorder = Color(0xFF3F3F3F);
  static const Color cardInner = Color(0xFFE6E6E6);

  // Bottom Navigation
  static const Color bottomBarBg = Color(0xFF2D2D2D);
  static const Color bottomIconInactive = Color(0xFF7C7C7C);
  static const Color bottomIconActive = Color(0xFFFFFFFF);
  static const Color bottomHighlight = Color(0xFFFAC60C);

  static Color shimmerBase = Colors.grey[800]!;
  static Color shimmerHighlight = Colors.grey[700]!;
}

/// 🔹 Extension on [BuildContext] for easy access to theme & typography
extension ThemeContextExtension on BuildContext {
  /// Access ThemeData
  ThemeData get theme => Theme.of(this);

  /// Access TextTheme (which defaults to Marcellus)
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick helper to create Marcellus TextStyle directly from context
  TextStyle marcellus({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.marcellus(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}
