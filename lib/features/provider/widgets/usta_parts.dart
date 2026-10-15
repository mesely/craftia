import 'package:flutter/material.dart';

import '../../../core/icons/usta_icon.dart';
import '../../../core/icons/usta_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/network_image.dart';
import '../../../data/models/usta.dart';
import '../../discovery/service_art.dart';

/// Profile photo, or — when there is none — the trade's own symbol on a calm tint.
class UstaAvatar extends StatelessWidget {
  const UstaAvatar({super.key, required this.usta, this.size = 56});

  final Usta usta;
  final double size;

  @override
  Widget build(BuildContext context) {
    const radius = AppRadius.borderMd;
    if (usta.profileImage != null) {
      return AppNetworkImage(
        url: usta.profileImage!,
        width: size,
        height: size,
        cacheWidth: (size * 3).round(),
        borderRadius: radius,
      );
    }
    return ServiceArt(
      size: size,
      mainType: usta.mainType,
      subType: usta.subType,
    );
  }
}

/// ★ 4,8 (12 yorum). A new provider says "Yeni usta" instead of a misleading 0.
class RatingLabel extends StatelessWidget {
  const RatingLabel({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.large = false,
  });

  final double rating;
  final int reviewCount;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = (large ? AppTypography.titleSm : AppTypography.label);
    if (rating <= 0) {
      return Text(
        'Yeni usta',
        style: style.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        UstaIcon(UstaIcons.star, size: large ? 22 : 18, color: AppColors.amber),
        Text(formatRating(rating), style: style),
        if (reviewCount > 0)
          Text('($reviewCount yorum)', style: AppTypography.bodySm),
      ],
    );
  }
}

/// Paid placement, labelled plainly. It never claims quality or certification.
class FeaturedLabel extends StatelessWidget {
  const FeaturedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Öne çıkan',
      style: AppTypography.caption.copyWith(
        color: AppColors.amberInk,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// The one trust mark: icon + words (never colour alone).
class VerifiedLabel extends StatelessWidget {
  const VerifiedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const UstaIcon(UstaIcons.verified, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'Doğrulanmış',
            style: AppTypography.label.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
