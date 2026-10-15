import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibility/ui_scale.dart';
import '../../../core/icons/usta_icon.dart';
import '../../../core/icons/usta_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Shared frame of the sign-in and registration screens: back button, title, one-column form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onBack,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  /// Pinned under the form (the primary action stays reachable with one thumb).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final gutter = context.ui.gutter;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed:
              onBack ??
              () => context.canPop() ? context.pop() : context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xl),
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: AppTypography.display),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                ],
              ),
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.sm,
                  gutter,
                  AppSpacing.lg,
                ),
                child: SizedBox(width: double.infinity, child: bottom),
              ),
          ],
        ),
      ),
    );
  }
}

/// A form field group with comfortable spacing.
class FormGap extends StatelessWidget {
  const FormGap({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.lg);
}
