import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/network_image.dart';
import '../../data/models/chat.dart';

/// One chat message. Mine on the right in brand blue, theirs on the left on white, system notes
/// centred and quiet. The request message is a small card so it is easy to find later.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.replyTarget,
    required this.replyAuthor,
    required this.onLongPress,
    required this.onImageTap,
  });

  final ChatMessage message;
  final bool mine;

  /// The message this one answers, if any.
  final ChatMessage? replyTarget;
  final String replyAuthor;
  final VoidCallback onLongPress;
  final void Function(String url) onImageTap;

  @override
  Widget build(BuildContext context) {
    if (message.kind == MessageKind.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(
              message.text,
              style: AppTypography.bodySm,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isRequest = message.kind == MessageKind.request;
    final fg = mine ? AppColors.onPrimary : AppColors.ink;
    final bg = mine ? AppColors.primary : AppColors.surface;
    final subtle = mine ? AppColors.primarySoft : AppColors.inkMuted;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.82;

    Widget content;
    if (message.isDeleted) {
      content = Text(
        'Mesaj silindi',
        style: AppTypography.body.copyWith(
          color: subtle,
          fontStyle: FontStyle.italic,
          fontSize: 15,
        ),
      );
    } else if (message.kind == MessageKind.image &&
        message.attachmentId != null) {
      final url = AppConfig.resolve('/attachments/${message.attachmentId}');
      content = GestureDetector(
        onTap: () => onImageTap(url),
        child: AppNetworkImage(
          url: url,
          width: 220,
          height: 220,
          cacheWidth: 660,
          borderRadius: AppRadius.borderSm,
        ),
      );
    } else if (isRequest) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UstaIcon(
                UstaIcons.requests,
                size: 18,
                color: mine ? AppColors.onPrimary : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Hizmet Talebi',
                style: AppTypography.label.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message.requestBody,
            style: AppTypography.body.copyWith(color: fg),
          ),
        ],
      );
    } else {
      content = Text(
        message.text,
        style: AppTypography.body.copyWith(color: fg),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md + 2,
              AppSpacing.sm + 2,
              AppSpacing.md + 2,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.lg),
                topRight: const Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(mine ? AppRadius.lg : AppRadius.sm),
                bottomRight: Radius.circular(
                  mine ? AppRadius.sm : AppRadius.lg,
                ),
              ),
              border: mine ? null : Border.fromBorderSide(AppBorders.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (replyTarget != null && !message.isDeleted)
                  _ReplyQuote(
                    target: replyTarget!,
                    author: replyAuthor,
                    onDark: mine,
                  ),
                content,
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${message.isEdited && !message.isDeleted ? 'düzenlendi · ' : ''}${formatClock(message.createdAt)}',
                    style: AppTypography.caption.copyWith(
                      color: subtle,
                      fontSize: 12,
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

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.target,
    required this.author,
    required this.onDark,
  });

  final ChatMessage target;
  final String author;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final line = onDark ? AppColors.primarySoft : AppColors.primary;
    final text = target.isDeleted
        ? 'Mesaj silindi'
        : target.kind == MessageKind.image
        ? 'Fotoğraf'
        : target.kind == MessageKind.request
        ? target.requestBody
        : target.text;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm + 2,
        AppSpacing.xs + 2,
        AppSpacing.sm,
        AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: onDark ? AppColors.onPrimaryTint : AppColors.primarySoft,
        borderRadius: AppRadius.borderSm,
        border: Border(left: BorderSide(color: line, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: AppTypography.caption.copyWith(
              color: onDark ? AppColors.onPrimary : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              color: onDark ? AppColors.primarySoft : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
