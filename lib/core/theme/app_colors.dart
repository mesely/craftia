import 'package:flutter/material.dart';

/// One complete set of colours. [AppColors] reads from the active palette.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.onPrimary,
    required this.onPrimaryTint,
    required this.amber,
    required this.amberSoft,
    required this.amberInk,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.artPlate,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;
  final Color onPrimary;
  final Color onPrimaryTint;
  final Color amber;
  final Color amberSoft;
  final Color amberInk;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;

  /// Paper-white plate behind the generated illustrations, which are drawn on white.
  final Color artPlate;

  // Contrast on the light background: ink 16:1, inkMuted 6.6:1, inkSubtle 5.2:1 (WCAG AA).
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFECEFF5),
    border: Color(0xFFDDE2EA),
    borderStrong: Color(0xFF7A879B),
    ink: Color(0xFF14181F),
    inkMuted: Color(0xFF4A5362),
    inkSubtle: Color(0xFF596372),
    primary: Color(0xFF0F4C9A),
    primaryPressed: Color(0xFF0A3A78),
    primarySoft: Color(0xFFDDE9F8),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryTint: Color(0x26FFFFFF),
    amber: Color(0xFFE29A12),
    amberSoft: Color(0xFFFBEFD3),
    amberInk: Color(0xFF8A5B00),
    success: Color(0xFF18714A),
    successSoft: Color(0xFFDDF1E6),
    danger: Color(0xFFB5322A),
    dangerSoft: Color(0xFFF8E1DE),
    artPlate: Color(0xFFFFFFFF),
  );

  // Contrast on the dark background: ink 15:1, inkMuted 8.9:1, inkSubtle 6.7:1.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0E1218),
    surface: Color(0xFF171C25),
    surfaceMuted: Color(0xFF222A36),
    border: Color(0xFF2C3544),
    borderStrong: Color(0xFF5B667A),
    ink: Color(0xFFEEF1F6),
    inkMuted: Color(0xFFB4BCC9),
    inkSubtle: Color(0xFF9AA3B2),
    primary: Color(0xFF6AA6F0),
    primaryPressed: Color(0xFF8FBBF4),
    primarySoft: Color(0xFF1C2F4A),
    onPrimary: Color(0xFF0A1B33),
    onPrimaryTint: Color(0x26000000),
    amber: Color(0xFFF0B03C),
    amberSoft: Color(0xFF3A2D10),
    amberInk: Color(0xFFF3C468),
    success: Color(0xFF4CC38A),
    successSoft: Color(0xFF16301F),
    danger: Color(0xFFF0675C),
    dangerSoft: Color(0xFF3A1B19),
    artPlate: Color(0xFFF4F6FA),
  );
}

/// Every colour used in the app lives here. Widgets never use raw hex values.
///
/// The values follow the active [AppPalette]; `UstaApp` switches it before each build and
/// rebuilds the tree when the brightness changes.
abstract final class AppColors {
  static AppPalette _p = AppPalette.light;

  static AppPalette get palette => _p;
  static bool get isDark => _p.brightness == Brightness.dark;

  static void apply(Brightness brightness) {
    _p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  }

  // Surfaces
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceMuted => _p.surfaceMuted;
  static Color get border => _p.border;
  static Color get borderStrong => _p.borderStrong;
  static Color get artPlate => _p.artPlate;

  // Ink
  static Color get ink => _p.ink;
  static Color get inkMuted => _p.inkMuted;
  static Color get inkSubtle => _p.inkSubtle;

  // Brand
  static Color get primary => _p.primary;
  static Color get primaryPressed => _p.primaryPressed;
  static Color get primarySoft => _p.primarySoft;
  static Color get onPrimary => _p.onPrimary;

  /// A soft wash for quoted text inside a primary-coloured chat bubble.
  static Color get onPrimaryTint => _p.onPrimaryTint;

  // Status
  static Color get amber => _p.amber;
  static Color get amberSoft => _p.amberSoft;
  static Color get amberInk => _p.amberInk;
  static Color get success => _p.success;
  static Color get successSoft => _p.successSoft;
  static Color get danger => _p.danger;
  static Color get dangerSoft => _p.dangerSoft;

  static const scrim = Color(0x66101820);
  static const shadow = Color(0x14101820);

  /// Soft tinted background for a colour.
  static Color tint(Color c) =>
      Color.alphaBlend(c.withValues(alpha: 0.12), surface);
}
