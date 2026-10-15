import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/choice_tile.dart';
import '../../data/models/filter_state.dart';
import '../location/location_controller.dart';
import 'discovery_providers.dart';

Future<void> showSortSheet(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _SortSheet());

class _SortSheet extends ConsumerWidget {
  const _SortSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(filtersProvider.select((f) => f.sortMode));
    final hasLocation = ref.watch(
      locationProvider.select((s) => s.hasLocation),
    );
    final gutter = context.ui.gutter;

    void choose(SortMode mode) {
      ref.read(filtersProvider.notifier).setSort(mode);
      if (mode == SortMode.nearest && !hasLocation) {
        // Explained on the home page; asking here is the user's own action.
        ref.read(locationProvider.notifier).request();
      }
      Navigator.of(context).pop();
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Nasıl sıralayalım?'),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxl),
            child: Column(
              children: [
                ChoiceTile(
                  label: SortMode.nearest.label,
                  caption: hasLocation
                      ? 'Sana en yakın ustalar üstte'
                      : 'Konum izni verirsen sana en yakın ustalar üstte olur',
                  selected: current == SortMode.nearest,
                  onTap: () => choose(SortMode.nearest),
                ),
                const SizedBox(height: AppSpacing.sm),
                ChoiceTile(
                  label: SortMode.rating.label,
                  caption: 'Müşterilerden en çok beğeni alanlar üstte',
                  selected: current == SortMode.rating,
                  onTap: () => choose(SortMode.rating),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
