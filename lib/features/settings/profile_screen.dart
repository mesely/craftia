import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.lg,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            const Text('Profil', style: AppTypography.display),
            const SizedBox(height: AppSpacing.xl),
            _HeroCard(onTap: () => context.push('/profile/become-provider')),
            const SizedBox(height: AppSpacing.xl),
            _Group(
              children: [
                _Row(
                  icon: PhosphorIconsRegular.lifebuoy,
                  label: 'Destek',
                  onTap: () => context.push('/profile/support'),
                ),
                _Row(
                  icon: PhosphorIconsRegular.compass,
                  label: 'Uygulama rehberi',
                  onTap: () => context.push('/profile/guide'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Group(
              children: [
                _Row(
                  icon: PhosphorIconsRegular.fileText,
                  label: 'Kullanıcı sözleşmesi',
                  onTap: () => context.push('/profile/legal/agreement'),
                ),
                _Row(
                  icon: PhosphorIconsRegular.shieldCheck,
                  label: 'KVKK aydınlatma metni',
                  onTap: () => context.push('/profile/legal/kvkk'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                'Usta v${AppConfig.appVersion}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSubtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ustasın, işini büyütmek mi istiyorsun?',
                      style: AppTypography.titleSm.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Hizmet veren olarak kaydol, çevrendeki müşteriler seni bulsun.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                PhosphorIconsBold.arrowRight,
                color: AppColors.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(indent: AppSpacing.lg + 28 + AppSpacing.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTypography.body)),
              const Icon(
                PhosphorIconsBold.caretRight,
                size: 16,
                color: AppColors.inkSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
