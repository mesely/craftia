import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/network_image.dart';
import '../../../data/models/usta.dart';

class UstaAvatar extends StatelessWidget {
  const UstaAvatar({super.key, required this.usta, this.size = 52});

  final Usta usta;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    if (usta.profileImage != null) {
      return AppNetworkImage(
        url: usta.profileImage!,
        width: size,
        height: size,
        cacheWidth: (size * 3).round(),
        borderRadius: radius,
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: radius,
      ),
      child: Text(
        initialsOf(usta.businessName),
        style: AppTypography.titleSm.copyWith(
          color: AppColors.primary,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

/// ★ 4,8 (12) — or a "Yeni" pill when nobody has reviewed yet. Never relies on colour alone.
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
    if (rating <= 0) {
      return Text(
        'Yeni',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIconsFill.star,
          size: large ? 18 : 14,
          color: AppColors.amber,
        ),
        const SizedBox(width: 3),
        Text(
          formatRating(rating),
          style: (large ? AppTypography.label : AppTypography.caption).copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (reviewCount > 0) ...[
          const SizedBox(width: 3),
          Text('($reviewCount)', style: AppTypography.caption),
        ],
      ],
    );
  }
}

/// Paid/featured placement, labelled plainly — no crown, no pill.
class FeaturedLabel extends StatelessWidget {
  const FeaturedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Öne çıkan',
      style: AppTypography.caption.copyWith(
        color: AppColors.amberInk,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class VerifiedMark extends StatelessWidget {
  const VerifiedMark({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Doğrulanmış usta',
      child: Icon(
        PhosphorIconsFill.sealCheck,
        size: size,
        color: AppColors.primary,
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
