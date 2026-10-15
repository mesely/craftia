import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibility/ui_scale.dart';
import '../../../core/icons/usta_icon.dart';
import '../../../core/icons/usta_icons.dart';
import '../../../core/theme/app_borders.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/distance.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/usta.dart';
import '../../../data/models/user_location.dart';
import 'usta_parts.dart';

/// One usta in a list, readable in about two seconds:
/// who (name, trade), how good (rating), where (district, distance), what it costs.
/// The whole card is the button; the call/message actions live on the detail page.
class UstaCard extends StatelessWidget {
  const UstaCard({super.key, required this.usta, this.userLocation});

  final Usta usta;
  final UserLocation? userLocation;

  @override
  Widget build(BuildContext context) {
    final distance = usta.distanceFrom(userLocation);
    final price = usta.startingPrice;

    final semantics = [
      usta.businessName,
      usta.subTypeText,
      if (usta.hasRating)
        'puan ${formatRating(usta.rating)}, ${usta.reviewCount} yorum',
      usta.locationLabel,
      if (distance != null) formatDistanceAway(distance),
      if (usta.isVerified) 'doğrulanmış',
      if (usta.isPremium) 'öne çıkan',
      price != null ? 'başlangıç ${formatLira(price)}' : 'fiyat için arayın',
      'Ayrıntıları görmek için dokun',
    ].join(', ');

    return Pressable(
      semanticLabel: semantics,
      onTap: () => context.push('/usta/${usta.id}', extra: usta),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.fromBorderSide(AppBorders.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UstaAvatar(usta: usta, size: context.ui.avatar - 12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usta.businessName,
                        style: AppTypography.titleSm,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Trade, rating and the two marks share one wrapping line.
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (usta.subTypeText.isNotEmpty)
                            Text(
                              usta.subTypeText,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          if (usta.hasRating)
                            RatingLabel(
                              rating: usta.rating,
                              reviewCount: usta.reviewCount,
                            ),
                          if (usta.isVerified) const VerifiedLabel(),
                          if (usta.isPremium) const FeaturedLabel(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _Where(usta: usta, distance: distance),
                      const SizedBox(height: 2),
                      _Signal(price: price),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: UstaIcon(
                    UstaIcons.chevronRight,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Güzelbahçe, İzmir · 27 km" on one line: the text shrinks a little instead of wrapping.
class _Where extends StatelessWidget {
  const _Where({required this.usta, required this.distance});

  final Usta usta;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final place = usta.locationLabel;
    final text = [
      if (place.isNotEmpty) place,
      if (distance != null) formatDistance(distance!),
    ].join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        UstaIcon(UstaIcons.pin, size: 16, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(text, style: AppTypography.bodySm, maxLines: 1),
          ),
        ),
      ],
    );
  }
}

/// The single price hint: "Başlangıç 1.000 ₺", or an invitation to call.
class _Signal extends StatelessWidget {
  const _Signal({required this.price});

  final double? price;

  @override
  Widget build(BuildContext context) {
    if (price == null) {
      return Text('Fiyat için arayın', style: AppTypography.bodySm);
    }
    return Text.rich(
      TextSpan(
        style: AppTypography.bodySm,
        children: [
          const TextSpan(text: 'Başlangıç '),
          TextSpan(
            text: formatLira(price!),
            style: AppTypography.label.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
