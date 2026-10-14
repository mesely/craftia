import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Inter, bundled with the app (works offline). Sentence case everywhere.
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.ink,
  );
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );
  static const titleSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );
  static const bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.inkMuted,
  );

  static TextTheme get textTheme => const TextTheme(
    displaySmall: display,
    headlineSmall: title,
    titleMedium: titleSm,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: bodySm,
    labelLarge: label,
    labelMedium: caption,
    labelSmall: caption,
  );
}
