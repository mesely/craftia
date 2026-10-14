import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/utils/distance.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/network_image.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/usta.dart';
import '../../../data/models/user_location.dart';
import 'usta_parts.dart';

/// One provider in a list: identity, trust signals, price signal, work preview, quick call.
class UstaCard extends ConsumerWidget {
  const UstaCard({super.key, required this.usta, this.userLocation});

  final Usta usta;
  final UserLocation? userLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = usta.distanceFrom(userLocation);
    final price = usta.startingPrice;
    final photos = usta.portfolioImages;

    final semantics = [
      usta.businessName,
      usta.subType,
      if (usta.hasRating) 'puan ${formatRating(usta.rating)}',
      if (distance != null) formatDistance(distance),
      if (usta.isVerified) 'doğrulanmış',
    ].join(', ');

    return Pressable(
      semanticLabel: semantics,
      onTap: () => context.push('/usta/${usta.id}', extra: usta),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UstaAvatar(usta: usta),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              usta.businessName,
                              style: AppTypography.titleSm,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (usta.isVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedMark(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          usta.subType,
                          usta.locationLabel,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: AppTypography.bodySm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          RatingLabel(
                            rating: usta.rating,
                            reviewCount: usta.reviewCount,
                          ),
                          if (distance != null)
                            InfoChip(
                              icon: PhosphorIconsFill.navigationArrow,
                              label: formatDistance(distance),
                            ),
                          if (usta.isPremium) const FeaturedLabel(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _PhotoStrip(photos: photos),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: price != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Başlangıç fiyatı',
                              style: AppTypography.caption,
                            ),
                            Text(
                              formatLira(price),
                              style: AppTypography.titleSm,
                            ),
                          ],
                        )
                      : const Text(
                          'Fiyat için arayın',
                          style: AppTypography.bodySm,
                        ),
                ),
                _CallButton(
                  label: '${usta.businessName} ara',
                  onPressed: () async {
                    final ok = await ref
                        .read(contactLauncherProvider)
                        .call(usta.phoneNumber);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Arama başlatılamadı. Numara: ${formatPhone(usta.phoneNumber)}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});

  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    final shown = photos.take(3).toList();
    final extra = photos.length - shown.length;
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.borderMd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: shown[i], cacheWidth: 240),
                    if (i == shown.length - 1 && extra > 0)
                      ColoredBox(
                        color: AppColors.scrim,
                        child: Center(
                          child: Text(
                            '+$extra',
                            style: AppTypography.label.copyWith(
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.primary,
        borderRadius: AppRadius.borderPill,
        child: InkWell(
          borderRadius: AppRadius.borderPill,
          onTap: onPressed,
          child: const SizedBox(
            height: AppSpacing.minTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg + 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsFill.phone,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Ara',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
