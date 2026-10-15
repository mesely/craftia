import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../data/models/auth_methods.dart';
import 'auth_controller.dart';
import 'identity.dart';
import 'widgets/auth_layout.dart';
import 'widgets/federated_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .signIn(_identifier.text, _password.text);
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

  /// With Firebase the account is an e-mail address, so the field says so.
  bool get _viaEmail =>
      ref.watch(identityProvider).available &&
      (ref.watch(authMethodsProvider).value?.allows(SignInMethod.email) ??
          false);

  Future<void> _forgot() async {
    final mail = _identifier.text.trim();
    if (Validators.email(mail) != null) {
      setState(() => _error = 'Önce e-posta adresini yaz, sonra buna dokun.');
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendPasswordReset(mail);
      if (!mounted) return;
      setState(() => _error = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Şifre yenileme bağlantısını $mail adresine gönderdik.',
            ),
          ),
        );
    } catch (e) {
      if (mounted) setState(() => _error = AppFailure.from(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Giriş yap',
      subtitle: _viaEmail
          ? 'Kayıt olurken kullandığın e-posta ve şifreyle gir.'
          : 'Kayıt olurken kullandığın e-posta ya da telefon numarasıyla gir.',
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
            : const Text('Giriş yap'),
      ),
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _identifier,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: InputDecoration(
                  labelText: _viaEmail ? 'E-posta' : 'E-posta veya telefon',
                ),
                validator: (v) => _viaEmail
                    ? Validators.email(v)
                    : Validators.required(
                        v,
                        'E-posta ya da telefon numaranı yaz.',
                        min: 5,
                      ),
              ),
              const FormGap(),
              TextFormField(
                controller: _password,
                obscureText: _hidden,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    child: Text(_hidden ? 'Göster' : 'Gizle'),
                  ),
                ),
                validator: (v) => (v ?? '').isEmpty ? 'Şifreni yaz.' : null,
              ),
            ],
          ),
        ),
        if (_viaEmail)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgot,
              child: const Text('Şifremi unuttum'),
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
        const FederatedButtons(),
        const SizedBox(height: AppSpacing.xl),
        Text('Hesabın yok mu?', style: AppTypography.titleSm),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.push('/register/customer'),
          child: const Text('Müşteri olarak kayıt ol'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.push('/register/provider'),
          child: const Text('Usta olarak kayıt ol'),
        ),
      ],
    );
  }
}
