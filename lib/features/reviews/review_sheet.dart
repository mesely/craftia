import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_sheet.dart';
import 'reviews_controller.dart';

Future<bool?> showReviewSheet(BuildContext context, String providerId) =>
    showAppSheet<bool>(
      context,
      builder: (_) => _ReviewSheet(providerId: providerId),
    );

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.providerId});

  final String providerId;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _comment = TextEditingController();
  final _name = TextEditingController();
  int _rating = 0;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Önce bir puan seç.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(reviewsProvider(widget.providerId).notifier)
          .submit(
            rating: _rating.toDouble(),
            comment: _comment.text.trim(),
            authorName: _name.text.trim().isEmpty
                ? 'Kullanıcı'
                : _name.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = AppFailure.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deneyimini paylaş', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Yorumun diğer kullanıcıların doğru ustayı bulmasına yardımcı olur.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Semantics(
                  button: true,
                  selected: i == _rating,
                  label: '$i yıldız',
                  child: InkResponse(
                    radius: 28,
                    onTap: () => setState(() => _rating = i),
                    child: SizedBox(
                      width: AppSpacing.minTap,
                      height: AppSpacing.minTap,
                      child: Icon(
                        i <= _rating
                            ? PhosphorIconsFill.star
                            : PhosphorIconsRegular.star,
                        size: 34,
                        color: i <= _rating
                            ? AppColors.amber
                            : AppColors.inkSubtle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Nasıl geçti? (isteğe bağlı)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Adın (isteğe bağlı)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.bodySm.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Yorumu gönder'),
            ),
          ),
        ],
      ),
    );
  }
}
