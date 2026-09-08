import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🔹 Centralized Typography configuration for Holy Nikkah.
/// Uses 'Marcellus' (serif) as the primary font family with ScreenUtil responsive sizes.
class AppTypography {
  AppTypography._();

  /// Primary font family name
  static const String fontFamily = 'Marcellus';

  /// Generates a [TextStyle] using the primary Marcellus font.
  static TextStyle marcellus({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    Color? decorationColor,
    TextBaseline? textBaseline,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.marcellus(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
      decorationColor: decorationColor,
      textBaseline: textBaseline,
      foreground: foreground,
      background: background,
      shadows: shadows,
    );
  }

  /// Base [TextTheme] built with Marcellus font family.
  static TextTheme createTextTheme([TextTheme? baseTheme]) {
    return GoogleFonts.marcellusTextTheme(baseTheme);
  }

  // Pre-configured Typography Presets with ScreenUtil responsive sizes (.sp)
  static TextStyle displayLarge({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 32.sp,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color,
      );

  static TextStyle displayMedium({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 28.sp,
        fontWeight: fontWeight ?? FontWeight.bold,
        color: color,
      );

  static TextStyle displaySmall({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 24.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color,
      );

  static TextStyle headline({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 20.sp,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color,
      );

  static TextStyle title({Color? color, FontWeight? fontWeight}) => marcellus(
    fontSize: 18.sp,
    fontWeight: fontWeight ?? FontWeight.w600,
    color: color,
  );

  static TextStyle subTitle({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color,
      );

  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 16.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 14.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) =>
      marcellus(
        fontSize: 12.sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color,
      );

  static TextStyle caption({Color? color, FontWeight? fontWeight}) => marcellus(
    fontSize: 10.sp,
    fontWeight: fontWeight ?? FontWeight.normal,
    color: color,
  );

  static TextStyle button({Color? color, FontWeight? fontWeight}) => marcellus(
    fontSize: 14.sp,
    fontWeight: fontWeight ?? FontWeight.w600,
    letterSpacing: 0.5,
    color: color,
  );
}
