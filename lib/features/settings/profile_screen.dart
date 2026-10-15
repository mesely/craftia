import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/account.dart';
import '../auth/auth_controller.dart';
import '../orders/requests_controller.dart';

/// Profilim: who I am here, and — for an usta — the small control panel for their listing.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider.select((s) => s.account));
    final gutter = context.ui.gutter;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: account == null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(gutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Profilini görmek için giriş yap',
                      style: AppTypography.titleSm,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Giriş yap'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxxl),
              children: [
                _Header(account: account),
                const SizedBox(height: AppSpacing.xxl),
                if (account.isProvider)
                  _ProviderPanel(account: account)
                else
                  _BecomeProviderCard(),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(account.name);
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.borderLg,
            border: Border.fromBorderSide(
              AppBorders.hairline.copyWith(color: AppColors.primary),
            ),
          ),
          child: Text(
            initials,
            style: AppTypography.title.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(account.name, style: AppTypography.title),
              ),
              Text(
                account.isProvider ? 'Usta hesabı' : 'Müşteri hesabı',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (account.phone.isNotEmpty)
                Text(formatPhone(account.phone), style: AppTypography.bodySm),
              if (account.email.isNotEmpty && !account.isDemo)
                Text(account.email, style: AppTypography.bodySm),
              if (account.isDemo)
                Text('Demo hesabı', style: AppTypography.bodySm),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderPanel extends ConsumerWidget {
  const _ProviderPanel({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Usta paneli', style: AppTypography.title),
        const SizedBox(height: AppSpacing.md),
        _ActionTile(
          icon: UstaIcons.requests,
          title: 'Gelen talepler',
          caption: unread > 0
              ? '$unread yeni mesajın var'
              : 'Müşterilerden gelen talepler ve mesajlar',
          onTap: () => context.go('/requests'),
        ),
        if (account.providerId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: UstaIcons.user,
            title: 'Müşterilerin gördüğü sayfam',
            caption: 'Profilini, fiyat listeni ve yorumlarını kontrol et',
            onTap: () => context.push('/usta/${account.providerId}'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: UstaIcons.pencil,
            title: 'Sayfamı düzenle',
            caption: 'Tanıtım, adres, fiyat listesi ve iş fotoğrafları',
            onTap: () => context.go('/page'),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const _FeaturedCard(),
      ],
    );
  }
}

/// What "Öne çıkan usta" means for an usta, in plain words, with a real way to ask for it.
class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.borderLg,
        border: Border.fromBorderSide(
          AppBorders.hairline.copyWith(color: AppColors.primary),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UstaIcon(UstaIcons.crown, size: 26, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Öne çıkan usta ol', style: AppTypography.title),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final line in const [
            'Aramalarda listenin en üstünde görünürsün.',
            'Kartında “Öne çıkan” etiketi olur.',
            'Daha çok müşteri sana ulaşır, daha çok iş alırsın.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: UstaIcon(
                      UstaIcons.check,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTypography.body.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.push('/promote'),
            child: const Text('Planları gör'),
          ),
        ],
      ),
    );
  }
}

class _BecomeProviderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ActionTile(
    icon: UstaIcons.hammer,
    title: 'Hizmet de mi veriyorsun?',
    caption: 'Aynı hesapla usta olarak kayıt ol, müşteriler seni bulsun.',
    onTap: () => context.push('/register/provider'),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final UstaIconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $caption',
    excludeSemantics: true,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMd,
        side: AppBorders.hairline,
      ),
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.ui.rowHeight + 8),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                UstaIcon(icon, size: 26, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleSm),
                      const SizedBox(height: 2),
                      Text(caption, style: AppTypography.bodySm),
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
      ),
    ),
  );
}
