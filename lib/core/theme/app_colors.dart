import 'package:flutter/material.dart';

/// Every colour used in the app lives here. Widgets never use raw hex values.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFF4F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFECEFF5);
  static const border = Color(0xFFDDE2EA);
  static const borderStrong = Color(0xFFA9B2C1);

  // Ink
  static const ink = Color(0xFF14181F);
  static const inkMuted = Color(0xFF4A5362);
  // Contrast on [background]: ink 16:1, inkMuted 6.6:1, inkSubtle 5.2:1 (WCAG AA).
  static const inkSubtle = Color(0xFF596372);

  // Brand
  static const primary = Color(0xFF0F4C9A);
  static const primaryPressed = Color(0xFF0A3A78);
  static const primarySoft = Color(0xFFDDE9F8);
  static const onPrimary = Color(0xFFFFFFFF);

  // Status
  static const amber = Color(0xFFE29A12);
  static const amberSoft = Color(0xFFFBEFD3);
  static const amberInk = Color(0xFF8A5B00);
  static const success = Color(0xFF1B7F52);
  static const successSoft = Color(0xFFDDF1E6);
  static const danger = Color(0xFFC0372D);
  static const dangerSoft = Color(0xFFF8E1DE);

  static const scrim = Color(0x66101820);
  static const shadow = Color(0x14101820);

  /// Soft tinted background for a colour.
  static Color tint(Color c) =>
      Color.alphaBlend(c.withValues(alpha: 0.12), surface);
}
