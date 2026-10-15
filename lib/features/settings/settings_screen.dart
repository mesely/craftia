import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/accessibility/ui_scale_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../core/widgets/choice_tile.dart';
import '../auth/auth_controller.dart';
import 'data_export.dart';

/// Ayarlar: how the app looks, the account, help, and the safety/legal texts.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.ui.gutter,
        AppSpacing.lg,
        context.ui.gutter,
        AppSpacing.xxl,
      ),
      children: [
        Semantics(
          header: true,
          child: Text('Ayarlar', style: AppTypography.display),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _UiSizeSection(),
        const SizedBox(height: AppSpacing.xxl),
        const _AppearanceSection(),
        const SizedBox(height: AppSpacing.xxl),
        if (auth.signedIn)
          _Group(
            title: 'Hesabım',
            children: [
              _Row(
                icon: UstaIcons.user,
                label: 'Profilim',
                caption: auth.account!.name,
                onTap: () => context.push('/profile'),
              ),
              _Row(
                icon: UstaIcons.download,
                label: 'Verilerimi indir',
                caption: 'Hesabın, taleplerin ve mesajların dosya olarak',
                onTap: () => exportMyData(context, ref),
              ),
              _Row(
                icon: UstaIcons.logout,
                label: 'Çıkış yap',
                onTap: () => _confirmSignOut(context, ref),
              ),
              _Row(
                icon: UstaIcons.trash,
                label: 'Hesabımı sil',
                caption: 'Kimlik bilgilerin kalıcı olarak kaldırılır',
                danger: true,
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          )
        else
          _Group(
            title: 'Hesabım',
            children: [
              _Row(
                icon: UstaIcons.user,
                label: 'Giriş yap',
                caption: 'Talep göndermek ve mesajlaşmak için',
                onTap: () => context.push('/login'),
              ),
              _Row(
                icon: UstaIcons.plus,
                label: 'Müşteri olarak kayıt ol',
                onTap: () => context.push('/register/customer'),
              ),
              _Row(
                icon: UstaIcons.hammer,
                label: 'Usta olarak kayıt ol',
                onTap: () => context.push('/register/provider'),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        _Group(
          title: 'Yardım',
          children: [
            _Row(
              icon: UstaIcons.help,
              label: 'Destek',
              onTap: () => context.push('/settings/support'),
            ),
            _Row(
              icon: UstaIcons.search,
              label: 'Uygulama rehberi',
              onTap: () => context.push('/settings/guide'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Group(
          title: 'Güvenlik ve yasal',
          children: [
            _Row(
              icon: UstaIcons.lock,
              label: 'Güvenli iletişim rehberi',
              onTap: () => context.push('/legal/safety'),
            ),
            _Row(
              icon: UstaIcons.flag,
              label: 'Şikayet ve resmi başvurular',
              onTap: () => context.push('/official'),
            ),
            _Row(
              icon: UstaIcons.document,
              label: 'Kullanıcı Sözleşmesi',
              onTap: () => context.push('/legal/agreement'),
            ),
            _Row(
              icon: UstaIcons.shield,
              label: 'KVKK Aydınlatma Metni',
              onTap: () => context.push('/legal/kvkk'),
            ),
            _Row(
              icon: UstaIcons.info,
              label: 'Sorumluluk Reddi',
              onTap: () => context.push('/legal/disclaimer'),
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
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış yapmak istiyor musun?'),
        content: const Text('İstediğin zaman tekrar giriş yapabilirsin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go('/welcome');
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabını silmek istiyor musun?'),
        content: const Text(
          'Kimlik bilgilerin kaldırılır ve bu işlem geri alınamaz. Anlaşmazlık ve güvenlik süreçleri için mesaj ve şikayet kayıtları, kimliğin kaldırılmış şekilde yasal süre boyunca saklanır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hesabımı sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (context.mounted) context.go('/welcome');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppFailure.from(e).message)));
      }
    }
  }
}

/// "Arayüz Boyutu": text, buttons and spacing grow together. The phone's own font size setting
/// still applies on top of this.
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
            UstaIcon(UstaIcons.textSize, size: 26, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Arayüz Boyutu', style: AppTypography.title),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
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

/// "Görünüm": light, dark, or follow the phone.
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final controller = ref.read(themeModeProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UstaIcon(UstaIcons.moon, size: 26, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Görünüm', style: AppTypography.title),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Açık ya da koyu renkler.', style: AppTypography.bodySm),
        const SizedBox(height: AppSpacing.md),
        for (final mode in AppThemeMode.values) ...[
          if (mode != AppThemeMode.values.first)
            const SizedBox(height: AppSpacing.sm),
          ChoiceTile(
            label: mode.label,
            caption: mode.description,
            selected: mode == current,
            onTap: () => controller.select(mode),
          ),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.sm,
            left: AppSpacing.xs,
          ),
          child: Semantics(
            header: true,
            child: Text(title, style: AppTypography.titleSm),
          ),
        ),
        Container(
          decoration: BoxDecoration(
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
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.danger = false,
  });

  final UstaIconData icon;
  final String label;
  final String? caption;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
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
              UstaIcon(
                icon,
                size: 24,
                color: danger ? AppColors.danger : AppColors.inkMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(color: color),
                    ),
                    if (caption != null)
                      Text(caption!, style: AppTypography.bodySm),
                  ],
                ),
              ),
              UstaIcon(
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
