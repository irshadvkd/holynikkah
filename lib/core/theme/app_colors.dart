import 'package:flutter/material.dart';

/// 🔹 Centralized App Color Tokens for HolyNikah
class AppColors {
  AppColors._();

  // ==========================================
  // Core Tokens
  // ==========================================

  /// Primary Color: Buttons, active states, CTAs, icons (#D4AF6A)
  static const Color primary = Color(0xFFD4AF6A);

  /// Primary Color Dark: Pressed/hover state of primary (#C9A24B)
  static const Color primaryDark = Color(0xFFC9A24B);

  /// Gold Light: Highlights, back buttons, VIP gradient start (#F3D68A)
  static const Color goldLight = Color(0xFFF3D68A);

  /// Gold Main: VIP gradient end, badge accents (#C9973F)
  static const Color goldMain = Color(0xFFC9973F);

  /// Gold Soft: Links, legal text highlights (#E2C98A)
  static const Color goldSoft = Color(0xFFE2C98A);

  /// Secondary Color: Cards, headers, secondary surfaces (#0E1F16)
  static const Color secondary = Color(0xFF0E1F16);

  /// Secondary Color Light: Gradient partner for secondary (or elevated cards) (#10241A)
  static const Color secondaryLight = Color(0xFF10241A);

  /// Background: App background (dark mode) (#070806)
  static const Color background = Color(0xFF070806);

  /// Surface: Cards, sheets, modals (#0E1F16)
  static const Color surface = Color(0xFF0E1F16);

  /// Primary Text: Main text on dark background (#E8E3D5)
  static const Color textPrimary = Color(0xFFE8E3D5);

  /// Secondary Text: Subtext, captions, timestamps (#9A9584)
  static const Color textSecondary = Color(0xFF9A9584);

  /// Muted Text: Body copy, captions on dark background (#9CB8AA)
  static const Color textMuted = Color(0xFF9CB8AA);

  /// Tertiary Text: Placeholder, disabled, hints (#7A8A75)
  static const Color textTertiary = Color(0xFF7A8A75);

  /// Border: Dividers, card outlines, hairlines (rgba(212, 175, 106, 0.2))
  static const Color border = Color(0x33D4AF6A);

  // ==========================================
  // Functional / Status Colors
  // ==========================================

  /// Success: Confirmed, verified, completed (#7A9B6E)
  static const Color success = Color(0xFF7A9B6E);

  /// Error: Failed action, required field, warning (#B5654A)
  static const Color error = Color(0xFFB5654A);

  /// Warning: Caution states (#E0B94F)
  static const Color warning = Color(0xFFE0B94F);

  /// Info: Neutral notices, tips (#8FA8C9)
  static const Color info = Color(0xFF8FA8C9);

  /// Disabled: Disabled buttons/inputs (#4A4A42)
  static const Color disabled = Color(0xFF4A4A42);

  /// Disabled Text: Text inside disabled elements (#5C5C52)
  static const Color textDisabled = Color(0xFF5C5C52);

  // ==========================================
  // Additional Utility & Interaction Colors
  // ==========================================

  /// Pure white — icons/text on colored buttons, rare full-contrast needs (#FFFFFF)
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black — shadows base, rare full-contrast needs (#000000)
  static const Color black = Color(0xFF000000);

  /// On Primary: Text/icons placed ON TOP of Primary Color buttons (#0E1F16)
  static const Color onPrimary = Color(0xFF0E1F16);

  /// On Secondary: Text/icons placed ON TOP of Secondary Color surfaces (#E8E3D5)
  static const Color onSecondary = Color(0xFFE8E3D5);

  /// Overlay: Modal/dialog backdrop, image darkening overlay (rgba(7, 8, 6, 0.6))
  static const Color overlay = Color(0x99070806);

  /// Shadow: Card elevation, drop shadows (rgba(0, 0, 0, 0.25))
  static const Color shadow = Color(0x40000000);

  /// Divider: Thin separators on dark surfaces (rgba(232, 227, 213, 0.12))
  static const Color divider = Color(0x1FE8E3D5);

  /// Link: Tappable text links (#D4AF6A - reuse Primary)
  static const Color link = primary;

  /// Icon Default: Default/inactive icon color (#9A9584 - reuse Secondary Text)
  static const Color iconDefault = textSecondary;

  /// Icon Active: Selected/active icon color (#D4AF6A - reuse Primary)
  static const Color iconActive = primary;

  /// Input Background: Text field fill (#10241A)
  static const Color inputBackground = Color(0xFF10241A);

  /// Input Border: Text field outline (rgba(212, 175, 106, 0.35))
  static const Color inputBorder = Color(0x59D4AF6A);

  /// Input Border Focused: Text field outline when active/focused (#D4AF6A)
  static const Color inputBorderFocused = primary;

  /// Placeholder: Empty input hint text (#7A8A75 - reuse Tertiary Text)
  static const Color placeholder = textTertiary;

  /// Scrim / Splash: Splash screen background, loading screen (#070806)
  static const Color scrim = Color(0xFF070806);
  static const Color splash = scrim;

  /// Gradient Start: For any gold-on-dark gradient buttons/headers (#0E1F16)
  static const Color gradientStart = Color(0xFF0E1F16);

  /// Gradient End: Pairs with Gradient Start (#10241A)
  static const Color gradientEnd = Color(0xFF10241A);

  /// 160deg Dark green gradient panel behind the mark: linear-gradient(160deg, #0e1f16, #10241a)
  static const LinearGradient darkGreenGradient = LinearGradient(
    begin: Alignment(-0.342, -0.940),
    end: Alignment(0.342, 0.940),
    colors: [
      Color(0xFF0E1F16),
      Color(0xFF10241A),
    ],
  );

  /// VIP Gold Gradient: [goldLight, goldMain]
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, goldMain],
  );

  // ==========================================
  // Shimmer Tokens
  // ==========================================
  static const Color shimmerBase = Color(0xFF0E1F16);
  static const Color shimmerHighlight = Color(0xFF10241A);
}