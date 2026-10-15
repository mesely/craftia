import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/icons/usta_icon.dart';
import '../../../core/icons/usta_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth_methods.dart';
import '../auth_controller.dart';
import '../federated_sign_in.dart';

/// "veya" + Google, Apple and SMS sign-in. The three buttons are always built and ready; each one
/// is enabled only when the server reports its method as switched on (Firebase configured).
class FederatedButtons extends ConsumerStatefulWidget {
  const FederatedButtons({super.key});

  @override
  ConsumerState<FederatedButtons> createState() => _FederatedButtonsState();
}

class _FederatedButtonsState extends ConsumerState<FederatedButtons> {
  SignInMethod? _busy;

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _go(SignInMethod method) async {
    setState(() => _busy = method);
    try {
      final token = await ref.read(federatedSignInProvider).idToken(method);
      final outcome = await ref
          .read(authProvider.notifier)
          .signInWith(method, token);
      if (!mounted || outcome == null) return;
      if (outcome.needsProfile) {
        final name = await _askName(outcome.suggested?['name'] ?? '');
        if (name == null || !mounted) return;
        await ref
            .read(authProvider.notifier)
            .completeFederated(
              token!,
              name: name,
              phone: outcome.suggested?['phone'],
            );
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) _toast(AppFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<String?> _askName(String suggested) {
    final controller = TextEditingController(text: suggested);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoş geldin'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Adın ve soyadın'),
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
    final methods = ref.watch(authMethodsProvider).value ?? AuthMethods.none;
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
        for (final m in SignInMethod.values) ...[
          OutlinedButton.icon(
            onPressed: methods.allows(m) && _busy == null ? () => _go(m) : null,
            icon: _busy == m
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : switch (m) {
                    SignInMethod.phone => UstaIcon(UstaIcons.phone, size: 20),
                    SignInMethod.google => const _Letter('G'),
                    SignInMethod.apple => const _Letter('A'),
                  },
            label: Text(m.label),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (!methods.anyFederated)
          Text(
            'Google, Apple ve SMS ile giriş yakında açılacak.',
            style: AppTypography.bodySm,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 20,
    child: Center(
      child: Text(
        letter,
        style: AppTypography.button.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
