import 'package:flutter/material.dart';

import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A number with a plain label: the usta's three-glance summary.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;

  /// Draws attention (something is waiting).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primarySoft : AppColors.surface,
          borderRadius: AppRadius.borderMd,
          border: Border.fromBorderSide(
            highlight
                ? AppBorders.hairline.copyWith(color: AppColors.primary)
                : AppBorders.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.display.copyWith(
                  color: highlight ? AppColors.primary : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTypography.bodySm),
          ],
        ),
      ),
    );
  }
}

/// A tappable row with an icon, used for the checklist and shortcuts.
class StudioRow extends StatelessWidget {
  const StudioRow({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    this.done = false,
    required this.onTap,
  });

  final UstaIconData icon;
  final String title;
  final String? caption;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '$title${done ? ', tamam' : ''}${caption == null ? '' : '. $caption'}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                UstaIcon(
                  done ? UstaIcons.checkCircle : icon,
                  size: 26,
                  color: done ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? AppColors.inkMuted : AppColors.ink,
                        ),
                      ),
                      if (caption != null)
                        Text(caption!, style: AppTypography.bodySm),
                    ],
                  ),
                ),
                UstaIcon(
                  UstaIcons.chevronRight,
                  size: 20,
                  color: AppColors.inkSubtle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White card with a hairline, the container for each dashboard block.
class StudioCard extends StatelessWidget {
  const StudioCard({super.key, required this.child, this.tinted = false});

  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tinted ? AppColors.primarySoft : AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.fromBorderSide(
          tinted
              ? AppBorders.hairline.copyWith(color: AppColors.primary)
              : AppBorders.hairline,
        ),
      ),
      child: child,
    );
  }
}
