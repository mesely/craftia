import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_sheet.dart';
import '../location/location_controller.dart';
import 'discovery_providers.dart';

Future<void> showFilterSheet(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _FilterSheet());

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late bool _limit;
  late double _km;

  @override
  void initState() {
    super.initState();
    final current = ref.read(filtersProvider).distanceKm;
    _limit = current != null;
    _km = current ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = ref.watch(
      locationProvider.select((s) => s.hasLocation),
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Filtreler'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Mesafeyi sınırla',
                    style: AppTypography.label,
                  ),
                  subtitle: Text(
                    hasLocation
                        ? 'Yalnızca belirlediğin yarıçaptaki ustalar listelenir.'
                        : 'Bunun için konum izni gerekiyor.',
                    style: AppTypography.bodySm,
                  ),
                  value: _limit && hasLocation,
                  activeThumbColor: AppColors.primary,
                  onChanged: hasLocation
                      ? (v) => setState(() => _limit = v)
                      : null,
                ),
                if (_limit && hasLocation) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Arama yarıçapı', style: AppTypography.bodySm),
                      Text('${_km.round()} km', style: AppTypography.label),
                    ],
                  ),
                  Slider(
                    min: 1,
                    max: 100,
                    divisions: 99,
                    value: _km,
                    label: '${_km.round()} km',
                    semanticFormatterCallback: (v) => '${v.round()} kilometre',
                    onChanged: (v) => setState(() => _km = v),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(filtersProvider.notifier).reset();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Temizle'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          ref
                              .read(filtersProvider.notifier)
                              .setDistance(_limit && hasLocation ? _km : null);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Uygula'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
