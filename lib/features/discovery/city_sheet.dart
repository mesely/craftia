import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/constants/cities.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_sheet.dart';
import '../location/location_controller.dart';
import 'discovery_providers.dart';

Future<void> showCitySheet(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _CitySheet());

class _CitySheet extends ConsumerStatefulWidget {
  const _CitySheet();

  @override
  ConsumerState<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends ConsumerState<_CitySheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(filtersProvider.select((f) => f.city));
    final needle = _search.trim().toLowerCase();
    final cities = needle.isEmpty
        ? kTurkishCities
        : kTurkishCities
              .where((c) => c.toLowerCase().contains(needle))
              .toList(growable: false);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Nerede arıyorsun?'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: _UseMyLocationTile(),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Şehir ara',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(AppSpacing.md + 2),
                  child: UstaIcon(
                    UstaIcons.search,
                    size: 24,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: cities.length + (needle.isEmpty ? 1 : 0),
              itemBuilder: (context, i) {
                final isAll = needle.isEmpty && i == 0;
                final city = isAll ? null : cities[needle.isEmpty ? i - 1 : i];
                final isSelected = city == selected;
                return ListTile(
                  minTileHeight: context.ui.rowHeight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  title: Text(
                    city ?? 'Tüm Türkiye',
                    style: AppTypography.body.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? UstaIcon(
                          UstaIcons.check,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    ref.read(filtersProvider.notifier).setCity(city);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UseMyLocationTile extends ConsumerWidget {
  const _UseMyLocationTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);
    final controller = ref.read(locationProvider.notifier);

    final (
      String title,
      String? subtitle,
      VoidCallback? onTap,
    ) = switch (state.status) {
      LocationStatus.available => (
        'Konumun alındı',
        'Yakın ustalar mesafeye göre sıralanıyor.',
        controller.request,
      ),
      LocationStatus.loading => ('Konumun alınıyor…', null, null),
      LocationStatus.deniedForever => (
        'Konum izni kapalı',
        'Ayarlardan izin verebilirsin.',
        controller.openSettings,
      ),
      LocationStatus.serviceDisabled => (
        'Konum servisi kapalı',
        'Açmak için dokun.',
        controller.openSettings,
      ),
      LocationStatus.unavailable => (
        'Konum alınamadı',
        'Tekrar denemek için dokun.',
        controller.request,
      ),
      _ => (
        'Konumumu kullan',
        'Sana en yakın ustaları göster.',
        controller.request,
      ),
    };

    return Material(
      color: AppColors.primarySoft,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              state.status == LocationStatus.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : UstaIcon(
                      state.hasLocation
                          ? UstaIcons.checkCircle
                          : UstaIcons.locate,
                      color: AppColors.primary,
                      size: 26,
                    ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.label),
                    if (subtitle != null)
                      Text(subtitle, style: AppTypography.bodySm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
