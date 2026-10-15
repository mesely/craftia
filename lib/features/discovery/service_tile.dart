import 'package:flutter/material.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/constants/services.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/art_image.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A service as a big, picture-first button: the illustration says it, the label confirms it.
/// Selection = border, tint *and* a check badge (never colour alone).
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.service,
    required this.selected,
    required this.onTap,
    this.horizontal = false,
    this.compact = false,
  });

  final ServiceOption service;
  final bool selected;
  final VoidCallback onTap;

  /// Picture beside the label (used when text is large and columns are fewer).
  final bool horizontal;

  /// Smaller picture and label, so the first screen also shows ustas.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final art = horizontal ? 56.0 : (compact ? 32.0 : 60.0);
    final image = ClipRRect(
      borderRadius: AppRadius.borderSm,
      child: ArtImage(
        service.art,
        width: art,
        height: art,
        cacheWidth: (art * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
    final label = Text(
      service.label,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.label.copyWith(
        fontSize: compact && !horizontal ? 12.5 : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: service.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: selected ? AppBorders.selected : AppBorders.hairline,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: horizontal
                  ? context.ui.rowHeight + 16
                  : (compact ? 68 : 108),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(
                    compact ? AppSpacing.sm : AppSpacing.sm + 2,
                  ),
                  child: horizontal
                      ? Row(
                          children: [
                            image,
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: label),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            image,
                            const SizedBox(height: AppSpacing.xs),
                            label,
                          ],
                        ),
                ),
                if (selected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: UstaIcon(
                          UstaIcons.check,
                          size: 14,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The nine services, 3 across (2 across when the text is large).
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.selectedId,
    required this.onSelect,
    this.compact = false,
  });

  final bool compact;
  final String? selectedId;
  final ValueChanged<ServiceOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final roomy = MediaQuery.textScalerOf(context).scale(16) > 17.5;
    final columns = roomy ? 2 : 3;
    final tiles = [
      for (final s in kServices)
        ServiceTile(
          service: s,
          selected: s.id == selectedId,
          horizontal: roomy,
          compact: compact,
          onTap: () => onSelect(s),
        ),
    ];
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += columns) ...[
          if (i > 0) SizedBox(height: compact ? 6 : AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) SizedBox(width: compact ? 6 : AppSpacing.sm),
                  Expanded(
                    child: i + j < tiles.length
                        ? tiles[i + j]
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
