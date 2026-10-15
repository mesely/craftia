import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'official_channels.dart';

/// "Şikayet ve resmi başvurular": what the app can and cannot do, and where to go.
class OfficialScreen extends StatelessWidget {
  const OfficialScreen({super.key});

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
        padding: EdgeInsets.fromLTRB(
          context.ui.gutter,
          0,
          context.ui.gutter,
          AppSpacing.xxxl,
        ),
        children: [
          Text('Şikayet ve resmi başvurular', style: AppTypography.display),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Usta, müşterilerle ustaları buluşturan bir ilan ve iletişim platformudur. İşin yapılması, ödeme ve anlaşmazlıklarda taraf değildir; bu konuların çözümü kullanıcılar arasındadır ve gerektiğinde resmi mercilere başvurulur.',
            style: AppTypography.body.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.borderMd,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UstaIcon(UstaIcons.flag, size: 24, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Uygulamadaki bir kullanıcıyı şikayet etmek için ustanın sayfasındaki ya da sohbetteki “Şikayet et” düğmesini kullan. Şikayetin kayıt altına alınır.',
                    style: AppTypography.body.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Resmi yollar', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          const OfficialChannels(),
        ],
      ),
    );
  }
}
