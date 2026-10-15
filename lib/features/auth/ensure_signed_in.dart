import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_sheet.dart';
import 'auth_controller.dart';

/// Browsing needs no account; writing does. Returns true when someone is signed in. Otherwise it
/// explains why in one sentence and offers the two ways in; the person then repeats the action.
Future<bool> ensureSignedIn(
  BuildContext context,
  WidgetRef ref, {
  String reason = 'Devam etmek için hesabına giriş yapmalısın.',
}) async {
  if (ref.read(authProvider).signedIn) return true;
  await showAppSheet<void>(
    context,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        context.ui.gutter,
        0,
        context.ui.gutter,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Giriş yapman gerekiyor', style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(reason, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text('Giriş yap'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/register/customer');
            },
            child: const Text('Müşteri olarak kayıt ol'),
          ),
        ],
      ),
    ),
  );
  return false;
}
