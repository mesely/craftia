import 'package:flutter/material.dart';

import '../accessibility/ui_scale.dart';
import '../icons/usta_icon.dart';
import '../icons/usta_icons.dart';
import '../theme/app_borders.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A large single-choice option. Selection is shown by border, fill *and* a check mark,
/// so it never relies on colour alone. Deliberately rectangular, not a pill.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.caption,
    this.enabled = true,
  });

  final String label;
  final String? caption;
  final UstaIconData? leading;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = enabled ? AppColors.ink : AppColors.inkSubtle;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: caption == null ? label : '$label. $caption',
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: selected ? AppBorders.selected : AppBorders.hairline,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.ui.rowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    UstaIcon(
                      leading!,
                      size: 26,
                      color: selected ? AppColors.primary : AppColors.inkMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppTypography.label.copyWith(color: ink),
                        ),
                        if (caption != null)
                          Text(
                            caption!,
                            style: AppTypography.bodySm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AppSpacing.sm),
                    UstaIcon(
                      UstaIcons.check,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
