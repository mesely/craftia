import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../location/location_controller.dart';

/// Calm Turkish explanation of why "nearest" is not active, with the one action that fixes it.
/// The app keeps working without location, so this is a hint, never a gate.
class LocationNotice extends ConsumerWidget {
  const LocationNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);
    final controller = ref.read(locationProvider.notifier);
    if (state.hasLocation || state.status == LocationStatus.loading) {
      return const SizedBox.shrink();
    }

    final (
      String text,
      String action,
      VoidCallback onTap,
    ) = switch (state.status) {
      LocationStatus.deniedForever => (
        'Konum izni kapalı. İstersen Ayarlar’dan açabilirsin; şimdilik puana göre sıralıyoruz.',
        'Ayarları aç',
        controller.openSettings,
      ),
      LocationStatus.serviceDisabled => (
        'Telefonunun konumu kapalı. Açarsan sana en yakın ustaları üste alırız.',
        'Konumu aç',
        controller.openSettings,
      ),
      LocationStatus.unavailable => (
        'Konumunu şu an alamadık. Ustalar puana göre sıralanıyor.',
        'Tekrar dene',
        controller.request,
      ),
      _ => (
        'Yakındaki ustaları gösterebilmemiz için konumunu kullanabiliriz.',
        'Konumumu kullan',
        controller.request,
      ),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.ui.gutter,
        0,
        context.ui.gutter,
        AppSpacing.md,
      ),
      child: Semantics(
        button: true,
        label: '$action. $text',
        excludeSemantics: true,
        child: Material(
          color: AppColors.primarySoft,
          borderRadius: AppRadius.borderMd,
          child: InkWell(
            borderRadius: AppRadius.borderMd,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: context.ui.rowHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const UstaIcon(
                      UstaIcons.locate,
                      size: 26,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action,
                            style: AppTypography.label.copyWith(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            text,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
