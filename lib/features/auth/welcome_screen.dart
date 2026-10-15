import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'auth_controller.dart';

class _Page {
  const _Page(this.art, this.title, this.body);
  final String art;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    'assets/onboarding/find.webp',
    'Aradığın usta, yakınında',
    'Elektrik, su tesisatı, klima, boya ve daha fazlası. İhtiyacını seç, sana en yakın ustaları gör.',
  ),
  _Page(
    'assets/onboarding/compare.webp',
    'Karşılaştır, güvenle seç',
    'Puanlara, yorumlara, fiyat listesine ve iş fotoğraflarına bak. Doğrulanmış ustaları kolayca tanı.',
  ),
  _Page(
    'assets/onboarding/contact.webp',
    'Ara ya da mesajlaş',
    'Ustayı hemen ara, uygulamadan yaz ya da hizmet talebi bırak. Yazışmaların güvenlik için kayıt altında tutulur.',
  ),
];

/// First launch: three calm intro pages, then a clear choice between the two ways in.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _last => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) => _controller.animateToPage(
    page,
    duration: AppDurations.normal,
    curve: Curves.easeOut,
  );

  Future<void> _browse() async {
    await ref.read(authProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.ui.gutter;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: context.ui.tapTarget + AppSpacing.sm,
              child: Align(
                alignment: Alignment.centerRight,
                child: _last
                    ? null
                    : Padding(
                        padding: EdgeInsets.only(right: gutter - 8),
                        child: TextButton(
                          onPressed: () => _go(_pages.length - 1),
                          child: const Text('Atla'),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _IntroPage(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Semantics(
                label: 'Sayfa ${_index + 1} / ${_pages.length}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: AppDurations.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.primary
                              : AppColors.borderStrong,
                          borderRadius: AppRadius.borderSm,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: AppDurations.normal,
                child: _last
                    ? _Choices(onBrowse: _browse)
                    : SizedBox(
                        key: const ValueKey('next'),
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _go(_index + 1),
                          child: const Text('Devam'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final art = (c.maxHeight * 0.6).clamp(120.0, 360.0);
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: context.ui.gutter),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.borderLg,
                  child: Image.asset(
                    page.art,
                    width: art,
                    height: art,
                    cacheWidth: 640,
                    excludeFromSemantics: true,
                    // The drawing's white paper takes the page's colour; in dark mode it
                    // stays a soft light plate so the blue lines remain readable.
                    color: AppColors.isDark
                        ? AppColors.artPlate
                        : AppColors.background,
                    colorBlendMode: BlendMode.multiply,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text(
                    page.title,
                    style: AppTypography.display,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  page.body,
                  style: AppTypography.body.copyWith(color: AppColors.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('choices'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoleCard(
          icon: UstaIcons.search,
          title: 'Usta arıyorum',
          caption: 'Müşteri olarak kayıt ol',
          primary: true,
          onTap: () => context.push('/register/customer'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RoleCard(
          icon: UstaIcons.hammer,
          title: 'Ustayım, iş arıyorum',
          caption: 'Usta olarak kayıt ol',
          onTap: () => context.push('/register/provider'),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('Zaten hesabım var · Giriş yap'),
          ),
        ),
        TextButton(
          onPressed: onBrowse,
          child: Text(
            'Şimdilik göz at',
            style: AppTypography.button.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
    this.primary = false,
  });

  final UstaIconData icon;
  final String title;
  final String caption;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.onPrimary : AppColors.ink;
    return Semantics(
      button: true,
      label: '$title. $caption',
      excludeSemantics: true,
      child: Material(
        color: primary ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: primary ? BorderSide.none : AppBorders.strong,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.ui.rowHeight + 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  UstaIcon(icon, size: 28, color: fg),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleSm.copyWith(color: fg),
                        ),
                        Text(
                          caption,
                          style: AppTypography.bodySm.copyWith(
                            color: primary
                                ? AppColors.primarySoft
                                : AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  UstaIcon(UstaIcons.chevronRight, size: 22, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
