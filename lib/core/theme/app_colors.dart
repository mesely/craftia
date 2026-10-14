import 'package:flutter/material.dart';

/// Every colour used in the app lives here. Widgets never use raw hex values.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFFF6F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFEDE8);
  static const border = Color(0xFFE4E1DA);

  // Ink
  static const ink = Color(0xFF17191C);
  static const inkMuted = Color(0xFF565C63);
  static const inkSubtle = Color(0xFF7A8087);

  // Brand
  static const primary = Color(0xFF0E5C63);
  static const primaryPressed = Color(0xFF0A474D);
  static const primarySoft = Color(0xFFDCEEEE);
  static const onPrimary = Color(0xFFFFFFFF);

  // Status
  static const amber = Color(0xFFE29A12);
  static const amberSoft = Color(0xFFFBEFD3);
  static const amberInk = Color(0xFF8A5B00);
  static const success = Color(0xFF1B7F52);
  static const successSoft = Color(0xFFDDF1E6);
  static const danger = Color(0xFFC0372D);
  static const dangerSoft = Color(0xFFF8E1DE);

  static const scrim = Color(0x66101214);
  static const shadow = Color(0x14101214);

  /// Soft tinted background for a colour.
  static Color tint(Color c) =>
      Color.alphaBlend(c.withValues(alpha: 0.12), surface);
}
