import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/choice_tile.dart';
import '../../data/models/category.dart';
import '../location/location_controller.dart';
import '../provider/widgets/usta_results.dart' show ustaCountLabel;
import 'category_icons.dart';
import 'city_sheet.dart';
import 'discovery_providers.dart';

Future<void> showFilterSheet(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _FilterSheet());

/// Distance options in kilometres. Plain choices beat a slider for most people.
const kDistanceOptions = <double>[5, 10, 25, 50];

/// Filters apply immediately; the button at the bottom shows how many ustas match.
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filtersProvider);
    final controller = ref.read(filtersProvider.notifier);
    final categories = ref.watch(categoriesProvider);
    final location = ref.watch(locationProvider);
    final query = ref.watch(providerQueryProvider);
    final gutter = context.ui.gutter;

    final category = categories
        .where((c) => c.id == filters.mainType)
        .firstOrNull;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Filtrele', style: AppTypography.title),
                      ),
                      if (filters.hasActiveRefinements)
                        TextButton(
                          onPressed: controller.reset,
                          child: const Text('Temizle'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (category != null) ...[
                    const _Label('Hizmet türü'),
                    _SubTypeChoices(
                      category: category,
                      selected: filters.subType,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  const _Label('Şehir'),
                  _CityRow(city: filters.city),
                  const SizedBox(height: AppSpacing.xl),
                  const _Label('Uzaklık'),
                  _DistanceChoices(
                    selected: filters.distanceKm,
                    hasLocation: location.hasLocation,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.sm,
              gutter,
              AppSpacing.lg,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Consumer(
                  builder: (context, ref, _) =>
                      Text(ustaCountLabel(ref.watch(ustaListProvider(query)))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(text, style: AppTypography.titleSm),
    ),
  );
}

class _SubTypeChoices extends ConsumerWidget {
  const _SubTypeChoices({required this.category, required this.selected});

  final ProviderCategory category;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(filtersProvider.notifier);
    return Column(
      children: [
        ChoiceTile(
          label: 'Hepsi',
          selected: selected == null,
          onTap: () => controller.selectSubType(null),
        ),
        for (final s in category.subTypes) ...[
          const SizedBox(height: AppSpacing.sm),
          ChoiceTile(
            leading: serviceIcon(mainType: category.id, subType: s.value),
            label: s.label,
            selected: selected == s.value,
            onTap: () => controller.selectSubType(s.value),
          ),
        ],
      ],
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city});

  final String? city;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Şehir: ${city ?? 'Tüm Türkiye'}. Değiştirmek için dokun',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: AppBorders.hairline,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: () => showCitySheet(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.ui.rowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      city ?? 'Tüm Türkiye',
                      style: AppTypography.label,
                    ),
                  ),
                  const UstaIcon(UstaIcons.chevronRight, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DistanceChoices extends ConsumerWidget {
  const _DistanceChoices({required this.selected, required this.hasLocation});

  final double? selected;
  final bool hasLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(filtersProvider.notifier);
    if (!hasLocation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yakındaki ustaları gösterebilmemiz için konum izni gerekiyor.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: ref.read(locationProvider.notifier).request,
            child: const Text('Konumumu kullan'),
          ),
        ],
      );
    }
    return Column(
      children: [
        ChoiceTile(
          label: 'Fark etmez',
          selected: selected == null,
          onTap: () => controller.setDistance(null),
        ),
        for (final km in kDistanceOptions) ...[
          const SizedBox(height: AppSpacing.sm),
          ChoiceTile(
            label: '${km.round()} km içinde',
            selected: selected == km,
            onTap: () => controller.setDistance(km),
          ),
        ],
      ],
    );
  }
}
