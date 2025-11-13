import 'package:flutter/material.dart';
import 'package:holynikkah/core/services/theme/app_colors.dart';
import 'package:holynikkah/core/services/theme/color_service.dart';
import 'package:holynikkah/core/services/theme/text_service.dart';

/// 🔹 Manages light/dark theme at runtime
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  AppColors get colors => ColorService.colors;

  ThemeData get lightThemeData => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: colors.background,
    primaryColor: colors.primary,
    textTheme: TextService.textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  ThemeData get darkThemeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: colors.background,
    primaryColor: colors.primary,
    textTheme: TextService.textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  /// Toggle theme dynamically
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
