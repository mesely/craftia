import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const _steps = [
    (
      UstaIcons.grid,
      'Hizmeti seç',
      'Ana sayfadan ihtiyacın olan hizmete dokun ya da arama kutusuna yaz. Şehrini seç ya da konumunu kullan.',
    ),
    (
      UstaIcons.sliders,
      'Filtrele',
      'Yakınlığa veya puana göre sırala, hizmet türünü ve uzaklığı seç.',
    ),
    (
      UstaIcons.search,
      'İncele',
      'Fiyat listesine, yapılan işlere ve yorumlara bak.',
    ),
    (
      UstaIcons.phone,
      'Ulaş',
      'Ara, mesaj gönder ya da hizmet talebi bırak. Dükkânı olan ustalar için Yol Tarifi de var.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
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
          Text('Uygulama rehberi', style: AppTypography.display),
          const SizedBox(height: AppSpacing.xs),
          Text(
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
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: UstaIcon(s.$1, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2, style: AppTypography.titleSm),
                          const SizedBox(height: 2),
                          Text(
                            s.$3,
                            style: AppTypography.body.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('Güvenlik ve sorumluluk', style: AppTypography.titleSm),
          const SizedBox(height: AppSpacing.sm),
          Text(
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
