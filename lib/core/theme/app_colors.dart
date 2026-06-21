import 'package:flutter/material.dart';

/// 🔹 App color scheme for light and dark themes
class AppColors {
  final Color primary;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color error;

  const AppColors({
    required this.primary,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.error,
  });

  static const light = AppColors(
    primary: Colors.blue,
    surface: Colors.white,
    textPrimary: Colors.black,
    textSecondary: Colors.grey,
    border: Color(0xFFE0E0E0),
    error: Colors.red,
  );

  static const dark = AppColors(
    primary: Colors.blue,
    surface: Colors.white,
    textPrimary: Colors.black,
    textSecondary: Colors.black87,
    border: Color(0xFFE0E0E0),
    error: Colors.red,
  );
}