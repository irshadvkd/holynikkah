import 'package:flutter/material.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

/// 🔹 Manages light/dark theme at runtime
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  ThemeData get lightThemeData => ThemeData(
    brightness: Brightness.light,
    fontFamily: AppTypography.fontFamily,
    textTheme: AppTypography.createTextTheme(),
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    cardColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.iconDefault,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  ThemeData get darkThemeData => ThemeData(
    brightness: Brightness.dark,
    fontFamily: AppTypography.fontFamily,
    textTheme: AppTypography.createTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    cardColor: AppColors.surface,
    dividerColor: AppColors.border,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.iconDefault,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  /// Get current theme
  ThemeData get currentTheme => _isDark ? darkThemeData : lightThemeData;

  /// Toggle theme dynamically
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}