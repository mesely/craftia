import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/accessibility/ui_scale_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/choice_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.ui.gutter,
            AppSpacing.lg,
            context.ui.gutter,
            AppSpacing.xxl,
          ),
          children: [
            const Text('Profil', style: AppTypography.display),
            const SizedBox(height: AppSpacing.xl),
            const _UiSizeSection(),
            const SizedBox(height: AppSpacing.xxl),
            _Group(
              children: [
                _Row(
                  icon: UstaIcons.user,
                  label: 'Usta olarak kaydol',
                  caption: 'Çevrendeki müşteriler seni bulsun',
                  onTap: () => context.push('/profile/become-provider'),
                ),
                _Row(
                  icon: UstaIcons.help,
                  label: 'Destek',
                  onTap: () => context.push('/profile/support'),
                ),
                _Row(
                  icon: UstaIcons.search,
                  label: 'Uygulama rehberi',
                  onTap: () => context.push('/profile/guide'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Group(
              children: [
                _Row(
                  icon: UstaIcons.document,
                  label: 'Kullanıcı sözleşmesi',
                  onTap: () => context.push('/profile/legal/agreement'),
                ),
                _Row(
                  icon: UstaIcons.shield,
                  label: 'KVKK aydınlatma metni',
                  onTap: () => context.push('/profile/legal/kvkk'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                'Usta v${AppConfig.appVersion}',
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Arayüz Boyutu": text, buttons and spacing grow together. The phone's own font
/// size setting still applies on top of this.
class _UiSizeSection extends ConsumerWidget {
  const _UiSizeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(uiScaleProvider);
    final controller = ref.read(uiScaleProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const UstaIcon(
              UstaIcons.textSize,
              size: 26,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                header: true,
                child: const Text('Arayüz Boyutu', style: AppTypography.title),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Yazıları ve düğmeleri sana uygun büyüklüğe getir.',
          style: AppTypography.bodySm,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final scale in UiScale.values) ...[
          if (scale != UiScale.normal) const SizedBox(height: AppSpacing.sm),
          ChoiceTile(
            label: scale.label,
            caption: scale.description,
            selected: scale == current,
            onTap: () => controller.select(scale),
          ),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.fromBorderSide(AppBorders.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: AppSpacing.lg),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
  });

  final UstaIconData icon;
  final String label;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: context.ui.rowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              UstaIcon(icon, size: 24, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.body),
                    if (caption != null)
                      Text(caption!, style: AppTypography.bodySm),
                  ],
                ),
              ),
              const UstaIcon(
                UstaIcons.chevronRight,
                size: 20,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
