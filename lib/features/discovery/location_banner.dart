import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../location/location_controller.dart';

/// Honest, Turkish explanation of why "nearest" is not active, with the one action that fixes it.
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
        'Yakındaki ustaları gösterebilmemiz için konum izni gerekiyor. İzni ayarlardan açabilirsin.',
        'Ayarları aç',
        controller.openSettings,
      ),
      LocationStatus.serviceDisabled => (
        'Konum servisi kapalı. Açarsan sana en yakın ustaları üste alırız.',
        'Konumu aç',
        controller.openSettings,
      ),
      LocationStatus.unavailable => (
        'Konumunu şu an alamadık. Ustalar puana göre sıralanıyor.',
        'Tekrar dene',
        controller.request,
      ),
      _ => (
        'Yakındaki ustaları gösterebilmemiz için konum izni gerekiyor.',
        'İzin ver',
        controller.request,
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsFill.mapPin,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(color: AppColors.ink),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
