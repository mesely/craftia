import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../constants/illustrations.dart';
import '../errors/app_failure.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Calm, centred message with an optional action. Used for empty and error states.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.title,
    this.icon,
    this.illustration,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData? icon;
  final String? illustration;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: compact ? AppSpacing.xxl : AppSpacing.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null)
            SvgPicture.asset(
              illustration!,
              width: 144,
              height: 108,
              excludeFromSemantics: true,
            )
          else if (icon != null)
            Icon(icon, size: 40, color: AppColors.inkSubtle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTypography.titleSm,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              style: AppTypography.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.compact = false,
  });

  final AppFailure failure;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final offline = failure.kind == FailureKind.network;
    return StateView(
      illustration: offline ? Illustrations.offline : null,
      icon: offline ? null : PhosphorIconsRegular.warningCircle,
      title: offline ? 'Bağlantı yok' : 'Bir sorun oluştu',
      message: failure.message,
      actionLabel: 'Tekrar dene',
      onAction: onRetry,
      compact: compact,
    );
  }
}
