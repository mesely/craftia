import 'package:flutter/material.dart';

import '../../core/constants/services.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/widgets/art_image.dart';
import 'category_icons.dart';

/// The illustration for a service, one per kind of work (see assets/services).
/// Drawn in one flat blue style so a klima looks like a klima and a boyacı like a boyacı.
/// Unknown services fall back to their category's art, then to the icon family.
String? serviceArtAsset({String? mainType, String? subType}) {
  final service = serviceFor(mainType: mainType, subType: subType);
  if (service != null) return service.art;
  return switch (mainType) {
    'TECHNICAL' => 'assets/services/elektrik.webp',
    'CONSTRUCTION' => 'assets/services/boya.webp',
    'TECH' => 'assets/services/elektronik.webp',
    'LIFE' => 'assets/services/temizlik.webp',
    _ => null,
  };
}

/// Square service illustration with the app's thumbnail shape; falls back to a symbol.
class ServiceArt extends StatelessWidget {
  const ServiceArt({
    super.key,
    required this.size,
    this.mainType,
    this.subType,
    this.radius = AppRadius.borderMd,
  });

  final double size;
  final String? mainType;
  final String? subType;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final asset = serviceArtAsset(mainType: mainType, subType: subType);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: asset == null ? AppColors.surface : AppColors.artPlate,
        borderRadius: radius,
        border: Border.fromBorderSide(AppBorders.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Center(
              child: UstaIcon(
                serviceIcon(mainType: mainType, subType: subType),
                size: size * 0.5,
                color: AppColors.primary,
              ),
            )
          : ArtImage(
              asset,
              // The whole drawing is always visible; only the empty margin meets the rounded frame.
              fit: BoxFit.contain,
              cacheWidth: (size * dpr).round(),
            ),
    );
  }
}
