import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const _steps = [
    (
      PhosphorIconsRegular.squaresFour,
      'Hizmeti seç',
      'Ana sayfadan kategoriyi ve alt hizmeti seç. Şehrini ya da konumunu belirt.',
    ),
    (
      PhosphorIconsRegular.slidersHorizontal,
      'Filtrele',
      'Yakınlığa veya puana göre sırala, mesafe sınırı koy.',
    ),
    (
      PhosphorIconsRegular.listMagnifyingGlass,
      'İncele',
      'Fiyat listesine, yapılan işlere ve yorumlara bak.',
    ),
    (
      PhosphorIconsRegular.phoneCall,
      'Ulaş',
      'Doğrudan ara, mesaj at ya da talep gönder.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(PhosphorIconsBold.arrowLeft),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.xxxl,
        ),
        children: [
          const Text('Uygulama rehberi', style: AppTypography.display),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Usta ile doğru ustaya dört adımda ulaş.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (final s in _steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Icon(s.$1, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2, style: AppTypography.titleSm),
                          const SizedBox(height: 2),
                          Text(s.$3, style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Güvenlik ve sorumluluk', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Usta, bağımsız hizmet verenlerle seni buluşturan bir platformdur. İşe başlamadan önce fiyatı netleştir; elden yapılan ödemeler platform güvencesi dışındadır.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sorular için: ${AppConfig.supportEmail}',
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}
