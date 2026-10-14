import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/models/usta.dart';
import '../location/location_controller.dart';
import '../orders/requests_controller.dart';

Future<bool?> showRequestSheet(BuildContext context, Usta usta) =>
    showAppSheet<bool>(context, builder: (_) => _RequestSheet(usta: usta));

class _RequestSheet extends ConsumerStatefulWidget {
  const _RequestSheet({required this.usta});

  final Usta usta;

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final location = ref.read(locationProvider).location;
      await ref
          .read(requestsProvider.notifier)
          .create(
            mainType: widget.usta.mainType,
            subType: widget.usta.subType,
            city: widget.usta.city,
            description: _description.text.trim(),
            providerId: widget.usta.id,
            contactPhone: _phone.text.trim(),
            location: location,
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
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.usta.businessName} için talep',
              style: AppTypography.title,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Sorununu kısaca anlat, usta seninle iletişime geçsin.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Örn. Mutfak musluğu damlatıyor, bu hafta bakılabilir mi?',
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Birkaç cümleyle anlat (en az 10 karakter).'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Telefon numaran (isteğe bağlı)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTypography.bodySm.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
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
                    : const Text('Talebi gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
