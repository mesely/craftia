import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth_methods.dart';
import '../auth_controller.dart';
import '../identity.dart';

/// "veya" + Google sign-in. It only appears when the app has Firebase and the server has Google
/// switched on; otherwise nothing is drawn (Apple and SMS are not offered at all).
class FederatedButtons extends ConsumerStatefulWidget {
  const FederatedButtons({super.key});

  @override
  ConsumerState<FederatedButtons> createState() => _FederatedButtonsState();
}

class _FederatedButtonsState extends ConsumerState<FederatedButtons> {
  bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      final auth = ref.read(authProvider.notifier);
      final outcome = await auth.signInWithGoogle();
      if (!mounted || outcome == null) return;
      if (outcome.needsProfile) {
        final name = await _askName(outcome.suggested?['name'] ?? '');
        if (name == null || !mounted) return;
        await auth.completeGoogle(name: name);
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askName(String suggested) {
    final controller = TextEditingController(text: suggested);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoş geldin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Adın ve soyadın'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Devam ederek Kullanıcı Sözleşmesi ve KVKK Aydınlatma Metni\'ni kabul etmiş olursun.',
              style: AppTypography.bodySm,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.length >= 2) Navigator.pop(ctx, v);
            },
            child: const Text('Müşteri olarak devam et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(identityProvider).available;
    final methods = ref.watch(authMethodsProvider).value ?? AuthMethods.none;
    if (!available || !methods.allows(SignInMethod.google)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('veya', style: AppTypography.bodySm),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _busy ? null : _google,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'G',
                  style: AppTypography.button.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
          label: Text(SignInMethod.google.label),
        ),
      ],
    );
  }
}
