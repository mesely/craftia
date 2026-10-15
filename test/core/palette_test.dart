import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/theme/app_colors.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final p in [AppPalette.light, AppPalette.dark]) {
    group('${p.brightness.name} palette meets WCAG AA', () {
      test('body text on every surface', () {
        for (final bg in [p.background, p.surface, p.surfaceMuted]) {
          expect(contrast(p.ink, bg), greaterThanOrEqualTo(7));
          expect(contrast(p.inkMuted, bg), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(p.inkSubtle, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.inkSubtle, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('brand and status colours are readable as text and as buttons', () {
        expect(contrast(p.primary, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.primary, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(p.primary, p.primarySoft), greaterThanOrEqualTo(4.5));
        expect(contrast(p.danger, p.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.danger, p.dangerSoft), greaterThanOrEqualTo(4.5));
        expect(contrast(p.success, p.successSoft), greaterThanOrEqualTo(4.5));
        expect(contrast(p.amberInk, p.amberSoft), greaterThanOrEqualTo(4.5));
        expect(contrast(p.amberInk, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('control borders are visible against the page', () {
        expect(contrast(p.borderStrong, p.background), greaterThanOrEqualTo(3));
      });
    });
  }

  test('AppColors follows the palette that was applied', () {
    addTearDown(() => AppColors.apply(Brightness.light));
    AppColors.apply(Brightness.dark);
    expect(AppColors.isDark, isTrue);
    expect(AppColors.background, AppPalette.dark.background);
    AppColors.apply(Brightness.light);
    expect(AppColors.background, AppPalette.light.background);
  });
}
