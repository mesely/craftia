import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import 'auth_controller.dart';
import 'widgets/auth_layout.dart';
import 'widgets/consent_checkbox.dart';

class CustomerRegisterScreen extends ConsumerStatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  ConsumerState<CustomerRegisterScreen> createState() =>
      _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState
    extends ConsumerState<CustomerRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _consent = false;
  bool _consentError = false;
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  List<TextEditingController> get _all => [_name, _phone, _email, _password];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    setState(() => _consentError = !_consent);
    if (!valid || !_consent) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider.notifier);
      await auth.registerCustomer(
        name: _name.text,
        phone: _phone.text,
        email: _email.text,
        password: _password.text,
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppFailure.from(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Müşteri kaydı',
      subtitle: 'Ustalara ulaşmak ve taleplerini takip etmek için hesap aç.',
      bottom: FilledButton(
        onPressed: _busy ? null : _submit,
        child: _busy
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : const Text('Kayıt ol'),
      ),
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Ad soyad'),
                validator: Validators.name,
              ),
              const FormGap(),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: '05XX XXX XX XX',
                ),
                validator: Validators.phone,
              ),
              const FormGap(),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: Validators.email,
              ),
              const FormGap(),
              TextFormField(
                controller: _password,
                obscureText: _hidden,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  helperText: 'En az 6 karakter',
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    child: Text(_hidden ? 'Göster' : 'Gizle'),
                  ),
                ),
                validator: Validators.password,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ConsentCheckbox(
          value: _consent,
          errorText: _consentError && !_consent
              ? 'Devam etmek için metinleri kabul etmelisin.'
              : null,
          onChanged: (v) => setState(() {
            _consent = v;
            _consentError = false;
          }),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: AppTypography.body.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: () => context.pushReplacement('/login'),
            child: const Text('Zaten hesabım var · Giriş yap'),
          ),
        ),
      ],
    );
  }
}
