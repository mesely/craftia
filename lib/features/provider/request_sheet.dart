import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/models/service_request.dart';
import '../../data/models/usta.dart';
import '../auth/auth_controller.dart';
import '../location/location_controller.dart';
import '../orders/requests_controller.dart';

/// "Hizmet talebi": what needs doing, in the customer's words. It becomes the first message of
/// the chat ("Hizmet Talebi: …"). Returns the created request, or null when dismissed.
Future<ServiceRequest?> showRequestSheet(BuildContext context, Usta usta) =>
    showAppSheet<ServiceRequest>(
      context,
      builder: (_) => _RequestSheet(usta: usta),
    );

class _RequestSheet extends ConsumerStatefulWidget {
  const _RequestSheet({required this.usta});

  final Usta usta;

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  final _form = GlobalKey<FormState>();
  late final _description = TextEditingController();
  late final _phone = TextEditingController(
    text: ref.read(authProvider).account?.phone ?? '',
  );
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
      final created = await ref
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
      if (mounted) Navigator.of(context).pop(created);
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
      padding: EdgeInsets.fromLTRB(
        context.ui.gutter,
        0,
        context.ui.gutter,
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
            Text(
              'Ne yapılması gerektiğini yaz. Mesajın ustaya “Hizmet Talebi” olarak gider ve sohbet açılır.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              maxLength: 600,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ne yapılması gerekiyor?',
                hintText:
                    'Örn. Mutfaktaki priz çalışmıyor, bu hafta bakılabilir mi?',
              ),
              validator: (v) => Validators.required(
                v,
                'Lütfen birkaç cümleyle anlat (en az 10 karakter).',
                min: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Telefon numaran (isteğe bağlı)',
                hintText: '05XX XXX XX XX',
                helperText: 'Usta seni gerekirse arayabilsin.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTypography.body.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onPrimary,
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
