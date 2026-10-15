import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/illustrations.dart';
import '../errors/app_failure.dart';
import '../icons/usta_icon.dart';
import '../icons/usta_icons.dart';
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

  final UstaIconData? icon;
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
        horizontal: AppSpacing.xxl,
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
            UstaIcon(icon!, size: 44, color: AppColors.inkSubtle),
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
              style: AppTypography.body.copyWith(
                color: AppColors.inkMuted,
                fontSize: 15,
              ),
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
    this.title = 'Şu anda yükleyemedik',
  });

  final AppFailure failure;
  final String title;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final offline = failure.kind == FailureKind.network;
    return StateView(
      illustration: offline ? Illustrations.offline : null,
      icon: offline ? null : UstaIcons.warning,
      title: offline
          ? 'İnternet bağlantısı yok'
          : 'Şu anda ustaları yükleyemedik',
      message: failure.message,
      actionLabel: 'Tekrar dene',
      onAction: onRetry,
      compact: compact,
    );
  }
}
