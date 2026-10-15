import 'package:flutter/material.dart';

import '../../core/icons/usta_icon.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import 'category_icons.dart';

/// The illustration for a service, one per kind of work (see assets/services).
/// Drawn in one flat blue style so a klima looks like a klima and a boyacı like a boyacı.
/// Unknown services fall back to their category's art, then to the icon family.
String? serviceArtAsset({String? mainType, String? subType}) {
  final t = foldTurkish(subType ?? '');
  const rules = <(String, String)>[
    ('elektrik', 'elektrikci'),
    ('tesisat', 'su-tesisatcisi'),
    ('klima', 'klima-kombi'),
    ('kombi', 'klima-kombi'),
    ('boya', 'boyaci'),
    ('dekorasyon', 'dekorasyon'),
    ('marangoz', 'marangoz'),
    ('beyaz esya', 'beyaz-esya'),
    ('camasir', 'beyaz-esya'),
    ('buzdolabi', 'beyaz-esya'),
    ('elektronik', 'elektronik'),
    ('televizyon', 'elektronik'),
    ('laptop', 'elektronik'),
    ('temizlik', 'ev-temizligi'),
  ];
  for (final (keyword, file) in rules) {
    if (t.contains(keyword)) return 'assets/services/$file.webp';
  }
  return switch (mainType) {
    'TECHNICAL' => 'assets/services/elektrikci.webp',
    'CONSTRUCTION' => 'assets/services/boyaci.webp',
    'TECH' => 'assets/services/elektronik.webp',
    'LIFE' => 'assets/services/ev-temizligi.webp',
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
        color: AppColors.surface,
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
          : Image.asset(
              asset,
              fit: BoxFit.cover,
              cacheWidth: (size * dpr).round(),
              excludeFromSemantics: true,
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}
