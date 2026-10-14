import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/constants/illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/filter_state.dart';
import '../../data/models/user_location.dart';
import '../../data/models/usta.dart';
import '../discovery/discovery_providers.dart';
import '../location/location_controller.dart';
import '../provider/widgets/usta_parts.dart';
import 'map_surface.dart';

/// Same filters as Keşfet, but only the nearest 50 and only what has a position.
final mapQueryProvider = Provider<ProviderQuery>((ref) {
  final base = ref.watch(providerQueryProvider);
  return ProviderQuery(
    filters: base.filters,
    userLat: base.userLat,
    userLng: base.userLng,
    pageSize: 50,
  );
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(mapQueryProvider);
    final list = ref.watch(ustaListProvider(query));
    final location = ref.watch(
      locationProvider.select((s) => s.hasLocation ? s.location : null),
    );
    final builder = ref.watch(mapSurfaceBuilderProvider);

    final ustas = list.items
        .where((u) => u.hasCoordinates)
        .toList(growable: false);
    final pins = <MapPin>[for (final u in ustas) ?MapPin.fromUsta(u)];
    final selected = ustas.where((u) => u.id == _selectedId).firstOrNull;

    Widget body;
    if (list.status == ListStatus.error) {
      body = Center(
        child: ErrorStateView(
          failure: list.failure!,
          onRetry: ref.read(ustaListProvider(query).notifier).refresh,
        ),
      );
    } else if (list.status == ListStatus.data && pins.isEmpty) {
      body = Center(
        child: StateView(
          illustration: Illustrations.locationPin,
          title: 'Haritada gösterecek usta bulamadık.',
          message: 'Kategoriyi ya da şehri değiştirip tekrar dene.',
          actionLabel: 'Filtreleri temizle',
          onAction: ref.read(filtersProvider.notifier).reset,
        ),
      );
    } else {
      body = builder.build(
        context,
        MapSurfaceData(
          pins: pins,
          user: location,
          selectedId: selected?.id,
          onPinTap: (id) => setState(() => _selectedId = id),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: body),
          const Positioned(top: 0, left: 0, right: 0, child: _TopBar()),
          Positioned(
            right: AppSpacing.gutter,
            bottom: selected == null ? AppSpacing.xl : 176,
            child: const _LocateButton(),
          ),
          if (list.status == ListStatus.loading)
            const Positioned(
              top: 132,
              left: 0,
              right: 0,
              child: Center(child: _LoadingChip()),
            ),
          Positioned(
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            bottom: AppSpacing.lg,
            child: selected == null
                ? (pins.isEmpty
                      ? const SizedBox.shrink()
                      : _CountChip(count: pins.length, total: list.total))
                : _SelectedCard(
                    key: ValueKey(selected.id),
                    usta: selected,
                    userLocation: location,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(filtersProvider.select((f) => f.mainType));
    final city = ref.watch(filtersProvider.select((f) => f.city));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: Row(
                  children: [
                    const Text('Harita', style: AppTypography.title),
                    const SizedBox(width: AppSpacing.sm),
                    Text(city ?? 'Tüm Türkiye', style: AppTypography.bodySm),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    final isSelected = c.id == selected;
                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label: c.name,
                      child: Material(
                        color: isSelected ? AppColors.ink : AppColors.surface,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.ink
                                : AppColors.border,
                          ),
                        ),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: () => ref
                              .read(filtersProvider.notifier)
                              .selectCategory(c.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Center(
                              child: Text(
                                c.shortName,
                                style: AppTypography.label.copyWith(
                                  color: isSelected
                                      ? AppColors.surface
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocateButton extends ConsumerWidget {
  const _LocateButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);
    final loading = state.status == LocationStatus.loading;
    return Semantics(
      button: true,
      label: 'Konumumu kullan',
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: loading ? null : ref.read(locationProvider.notifier).request,
          child: SizedBox(
            width: 52,
            height: 52,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(
                    state.hasLocation
                        ? PhosphorIconsFill.crosshair
                        : PhosphorIconsRegular.crosshair,
                    color: state.hasLocation
                        ? AppColors.primary
                        : AppColors.ink,
                  ),
          ),
        ),
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderPill,
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.sm),
          Text('Ustalar yükleniyor', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = total > count
        ? '$count usta gösteriliyor · toplam $total'
        : '$count usta';
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderPill,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _SelectedCard extends ConsumerWidget {
  const _SelectedCard({
    super.key,
    required this.usta,
    required this.userLocation,
  });

  final Usta usta;
  final UserLocation? userLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = usta.distanceFrom(userLocation);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              UstaAvatar(usta: usta, size: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usta.businessName,
                      style: AppTypography.titleSm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        usta.subType,
                        usta.locationLabel,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: AppTypography.bodySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      children: [
                        RatingLabel(
                          rating: usta.rating,
                          reviewCount: usta.reviewCount,
                        ),
                        if (distance != null)
                          InfoChip(
                            icon: PhosphorIconsFill.navigationArrow,
                            label: formatDistance(distance),
                          ),
                        if (usta.isPremium) const FeaturedLabel(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      context.push('/usta/${usta.id}', extra: usta),
                  child: const Text('Profili aç'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SquareAction(
                label: 'Yol tarifi',
                icon: PhosphorIconsRegular.navigationArrow,
                onTap: () async {
                  final ok = await ref
                      .read(contactLauncherProvider)
                      .maps(
                        lat: usta.lat,
                        lng: usta.lng,
                        query: usta.businessName,
                      );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Harita uygulaması açılamadı.'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _SquareAction(
                label: 'Ara',
                icon: PhosphorIconsFill.phone,
                onTap: () async {
                  final ok = await ref
                      .read(contactLauncherProvider)
                      .call(usta.phoneNumber);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Arama başlatılamadı. Numara: ${formatPhone(usta.phoneNumber)}',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, size: 22, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
