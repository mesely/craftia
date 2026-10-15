import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/choice_tile.dart';
import '../location/location_controller.dart';
import 'discovery_providers.dart';

/// Distance options in kilometres. Plain choices beat a slider for most people.
const kDistanceOptions = <double>[5, 10, 25, 50];

Future<void> showDistanceSheet(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _DistanceSheet());

/// "Uzaklık": how far from you to look. Needs the phone's location; says so when it is missing.
class _DistanceSheet extends ConsumerWidget {
  const _DistanceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filtersProvider.select((f) => f.distanceKm));
    final hasLocation = ref.watch(
      locationProvider.select((s) => s.hasLocation),
    );
    final controller = ref.read(filtersProvider.notifier);
    final gutter = context.ui.gutter;

    void choose(double? km) {
      controller.setDistance(km);
      Navigator.of(context).pop();
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Ne kadar yakında arayalım?'),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxl),
            child: hasLocation
                ? Column(
                    children: [
                      ChoiceTile(
                        label: 'Fark etmez',
                        selected: selected == null,
                        onTap: () => choose(null),
                      ),
                      for (final km in kDistanceOptions) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ChoiceTile(
                          label: '${km.round()} km içinde',
                          selected: selected == km,
                          onTap: () => choose(km),
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yakındaki ustaları gösterebilmemiz için konumunu kullanabiliriz.',
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () {
                          ref.read(locationProvider.notifier).request();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Konumumu kullan'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
