import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../icons/usta_icon.dart';
import '../icons/usta_icons.dart';
import '../theme/app_colors.dart';

/// Lazy, cached image with placeholder and graceful failure. [cacheWidth] keeps decoded size small.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.cacheWidth = 400,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final double? width;
  final double? height;
  final int cacheWidth;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      maxWidthDiskCache: 1000,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => const ColoredBox(color: AppColors.surfaceMuted),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.surfaceMuted,
        child: Center(
          child: UstaIcon(
            UstaIcons.image,
            color: AppColors.inkSubtle,
            size: 26,
          ),
        ),
      ),
    );
    return borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
