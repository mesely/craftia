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
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
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
                UstaAvatar(usta: usta, size: context.ui.avatar),
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (usta.isVerified || usta.isPremium) ...[
                        Wrap(
                          spacing: AppSpacing.md,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (usta.isVerified) const VerifiedLabel(),
                            if (usta.isPremium) const FeaturedLabel(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Text(
                        usta.businessName,
                        style: AppTypography.titleSm,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (usta.subTypeText.isNotEmpty)
                        Text(
                          usta.subTypeText,
                          style: AppTypography.body.copyWith(
                            color: AppColors.inkMuted,
                            fontSize: 15,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      RatingLabel(
                        rating: usta.rating,
                        reviewCount: usta.reviewCount,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _Where(usta: usta, distance: distance),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            // Wrap: on a big text size the action drops under the price instead of overflowing.
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  _Signal(price: price),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Ustayı Gör',
                          style: AppTypography.button.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const UstaIcon(
                        UstaIcons.chevronRight,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Where extends StatelessWidget {
  const _Where({required this.usta, required this.distance});

  final Usta usta;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final place = usta.locationLabel;
    final text = [
      if (place.isNotEmpty) place,
      if (distance != null) formatDistanceAway(distance!),
    ].join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: UstaIcon(UstaIcons.pin, size: 18, color: AppColors.inkMuted),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, style: AppTypography.bodySm)),
      ],
    );
  }
}

/// The single price hint at the bottom of a card.
class _Signal extends StatelessWidget {
  const _Signal({required this.price});

  final double? price;

  @override
  Widget build(BuildContext context) {
    if (price != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Başlangıç fiyatı', style: AppTypography.caption),
          Text(formatLira(price!), style: AppTypography.titleSm),
        ],
      );
    }
    return const Text('Fiyat için arayın', style: AppTypography.bodySm);
  }
}
