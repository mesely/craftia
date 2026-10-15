import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The illustrations are drawn in blue on white paper. In the light theme the paper takes the
/// colour it sits on; in the dark theme the picture is turned around (white paper becomes a deep
/// blue plate, the dark outlines become light blue) so every drawing stays clearly recognisable.
class ArtImage extends StatelessWidget {
  const ArtImage(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.cacheWidth,
    this.paper,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;

  /// Light theme only: the colour the white paper blends into (default: pure white).
  final Color? paper;

  /// Inverts luminance and rotates hue by 180° so blues stay blue, then lifts black to [plate].
  static ColorFilter darkFilter(Color plate) {
    const h = [
      [-0.574, 1.430, 0.144],
      [0.426, 0.430, 0.144],
      [0.426, 1.430, -0.856],
    ];
    final bias = [plate.r * 255, plate.g * 255, plate.b * 255];
    return ColorFilter.matrix([
      for (var i = 0; i < 3; i++) ...[
        -h[i][0],
        -h[i][1],
        -h[i][2],
        0,
        255 + bias[i],
      ],
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
      color: dark ? null : (paper ?? AppColors.artPlate),
      colorBlendMode: dark ? null : BlendMode.multiply,
      frameBuilder: dark
          ? (context, child, frame, sync) => ColorFiltered(
              colorFilter: darkFilter(AppColors.artPlate),
              child: child,
            )
          : null,
    );
  }
}
