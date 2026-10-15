import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/network_image.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/complaint.dart';
import '../../data/models/review.dart';
import '../../data/models/service_price.dart';
import '../../data/models/usta.dart';
import '../auth/auth_controller.dart';
import '../auth/ensure_signed_in.dart';
import '../discovery/discovery_providers.dart';
import '../location/location_controller.dart';
import '../reviews/review_sheet.dart';
import '../reviews/reviews_controller.dart';
import 'contact_sheet.dart';
import 'image_viewer.dart';
import 'widgets/usta_parts.dart';

class UstaDetailScreen extends ConsumerWidget {
  const UstaDetailScreen({super.key, required this.id, this.initial});

  final String id;

  /// The list item that was tapped: lets the page render instantly while fresh data loads.
  final Usta? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref.watch(ustaDetailProvider(id));
    final usta = fresh.value ?? initial;

    if (usta == null) {
      return Scaffold(
        appBar: AppBar(leading: const _BackButton()),
        body: fresh.hasError
            ? Center(
                child: ErrorStateView(
                  failure: AppFailure.from(fresh.error!),
                  onRetry: () => ref.invalidate(ustaDetailProvider(id)),
                ),
              )
            : const _DetailSkeleton(),
      );
    }
    return _DetailBody(usta: usta);
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Geri',
      icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
      onPressed: () => context.canPop() ? context.pop() : context.go('/'),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(
      locationProvider.select((s) => s.hasLocation ? s.location : null),
    );
    final distance = usta.distanceFrom(location);
    final gutter = context.ui.gutter;
    final mine =
        ref.watch(authProvider.select((s) => s.account?.providerId)) == usta.id;

    return Scaffold(
      appBar: AppBar(leading: const _BackButton()),
      bottomNavigationBar: mine ? const _OwnerBar() : _ActionBar(usta: usta),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxxl),
        children: [
          _Identity(usta: usta, distance: distance),
          _Where(usta: usta),
          if (usta.about.isNotEmpty) ...[
            const _SectionTitle('Hakkında'),
            Text(usta.about, style: AppTypography.body),
          ],
          const _SectionTitle('Fiyat listesi'),
          _PriceList(usta: usta),
          const _SectionTitle('Yapılan işler'),
          _Portfolio(images: usta.portfolioImages),
          _ReviewsSection(usta: usta),
          if (!mine) _ReportLink(usta: usta),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.top = AppSpacing.xxxl});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: AppSpacing.md),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTypography.title),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.usta, required this.distance});

  final Usta usta;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final place = [
      if (usta.locationLabel.isNotEmpty) usta.locationLabel,
      if (distance != null) formatDistanceAway(distance!),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UstaAvatar(usta: usta, size: 92),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(usta.businessName, style: AppTypography.title),
                  ),
                  if (usta.subTypeText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      usta.subTypeText,
                      style: AppTypography.body.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                  if (usta.isVerified || usta.isPremium) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (usta.isVerified) const VerifiedLabel(),
                        if (usta.isPremium) const FeaturedLabel(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (usta.hasRating) ...[
          const SizedBox(height: AppSpacing.lg),
          RatingLabel(
            rating: usta.rating,
            reviewCount: usta.reviewCount,
            large: true,
          ),
        ],
        if (place.isNotEmpty) ...[
          SizedBox(height: usta.hasRating ? AppSpacing.sm : AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: UstaIcon(
                  UstaIcons.pin,
                  size: 20,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(place, style: AppTypography.body)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Plain rows with hairlines: a price list reads like a list, not a stack of cards.
class _PriceList extends StatelessWidget {
  const _PriceList({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context) {
    if (usta.priceList.isEmpty) {
      return const _InlineEmpty(
        text: 'Bu usta henüz fiyat listesi eklememiş. Net fiyat için arayabilirsin.',
      );
    }
    // At very large text the price moves under its name instead of squeezing it.
    final stacked = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Column(
      children: [
        for (var i = 0; i < usta.priceList.length; i++) ...[
          if (i > 0) const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usta.priceList[i].serviceName,
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _priceText(usta.priceList[i]),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          usta.priceList[i].serviceName,
                          style: AppTypography.body,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _priceText(usta.priceList[i], end: true),
                    ],
                  ),
          ),
        ],
        const Divider(),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            'Fiyatlar tahminidir; kesin tutar için ustayla konuş.',
            style: AppTypography.bodySm,
          ),
        ),
      ],
    );
  }
}

Widget _priceText(ServicePrice price, {bool end = false}) => Text(
  price.priceLabel,
  style: price.hasPrice ? AppTypography.titleSm : AppTypography.bodySm,
  textAlign: end ? TextAlign.end : TextAlign.start,
);

/// Up to six thumbnails in a 3-up grid; the sixth says how many more there are.
class _Portfolio extends StatelessWidget {
  const _Portfolio({required this.images});

  final List<String> images;

  static const _maxShown = 6;
  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _InlineEmpty(text: 'Henüz iş fotoğrafı eklenmemiş.');
    }
    final shown = images.take(_maxShown).toList();
    final extra = images.length - shown.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final side = (constraints.maxWidth - gap * (_columns - 1)) / _columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < shown.length; i++)
              Semantics(
                button: true,
                label:
                    'İş fotoğrafı ${i + 1} / ${images.length}. Büyütmek için dokun',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => openImageViewer(context, images, i),
                  child: SizedBox.square(
                    dimension: side,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          url: shown[i],
                          width: side,
                          height: side,
                          cacheWidth: (side * 2.5).round(),
                          borderRadius: AppRadius.borderSm,
                        ),
                        if (i == shown.length - 1 && extra > 0)
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppColors.scrim,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Center(
                              child: Text(
                                '+$extra',
                                style: AppTypography.titleSm.copyWith(
                                  color: AppColors.surface,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.borderMd,
      ),
      child: Text(text, style: AppTypography.body.copyWith(fontSize: 15)),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewsProvider(usta.id));
    final controller = ref.read(reviewsProvider(usta.id).notifier);

    Widget content;
    if (state.loading) {
      content = const SkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 72, radius: 12),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 72, radius: 12),
          ],
        ),
      );
    } else if (state.failure != null) {
      content = ErrorStateView(
        failure: state.failure!,
        onRetry: controller.load,
        compact: true,
      );
    } else if (state.items.isEmpty) {
      content = const _InlineEmpty(
        text: 'Henüz yorum yok. Bu ustayla çalıştıysan ilk yorumu sen yaz.',
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < state.items.length; i++) ...[
            if (i > 0) const Divider(),
            _ReviewTile(review: state.items[i]),
          ],
          if (state.hasMore)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: state.loadingMore ? null : controller.loadMore,
                child: Text(
                  state.loadingMore ? 'Yükleniyor…' : 'Daha fazla yorum göster',
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xxxl,
            bottom: AppSpacing.sm,
          ),
          // Wrap: with big text the button drops under the heading instead of overflowing.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  state.total > 0 ? 'Yorumlar (${state.total})' : 'Yorumlar',
                  style: AppTypography.title,
                ),
              ),
              TextButton.icon(
                icon: const UstaIcon(UstaIcons.pencil, size: 20),
                label: const Text('Yorum yaz'),
                onPressed: () async {
                  if (!await ensureSignedIn(
                    context,
                    ref,
                    reason: 'Yorum yazmak için hesabına giriş yapmalısın.',
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  final sent = await showReviewSheet(context, usta.id);
                  if (sent == true && context.mounted) {
                    ref.invalidate(ustaDetailProvider(usta.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Yorumun için teşekkürler!'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        content,
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.authorName, style: AppTypography.titleSm),
              ),
              RatingLabel(rating: review.rating, reviewCount: 0),
            ],
          ),
          Text(formatDate(review.createdAt), style: AppTypography.bodySm),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.comment, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

/// A calm, always-findable way to report a problem with this usta.
class _ReportLink extends ConsumerWidget {
  const _ReportLink({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bu ustayla ilgili bir sorun mu yaşadın? Dolandırıcılık, kaba davranış ya da yanlış bilgi şüphesini bize bildirebilirsin.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            icon: const UstaIcon(UstaIcons.flag, size: 20),
            label: const Text('Şikayet et'),
            onPressed: () async {
              if (!await ensureSignedIn(
                context,
                ref,
                reason: 'Şikayet etmek için hesabına giriş yapmalısın.',
              )) {
                return;
              }
              if (!context.mounted) return;
              context.push(
                '/complaint',
                extra: ComplaintTarget(
                  type: ComplaintTargetType.provider,
                  id: usta.id,
                  name: usta.businessName,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Address + "Yol Tarifi" for ustas with a shop; "Hizmet bölgesi" for those who travel.
/// Not every usta has a shop, so the page never pretends one exists.
class _Where extends ConsumerWidget {
  const _Where({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasShop = usta.hasShopAddress;
    final areas = usta.serviceAreas.isNotEmpty
        ? usta.serviceAreas.join(' · ')
        : usta.locationLabel;
    final canNavigate =
        hasShop && (usta.hasCoordinates || usta.address.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(hasShop ? 'Adres' : 'Hizmet bölgesi', top: AppSpacing.xl),
        if (hasShop)
          Text(usta.address, style: AppTypography.body)
        else ...[
          Text(
            areas.isEmpty ? 'Bölge bilgisi eklenmemiş.' : areas,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bu usta için sabit bir adres paylaşılmamış. Size gelip gelemeyeceğini ustaya sorabilirsin.',
            style: AppTypography.bodySm,
          ),
        ],
        if (canNavigate) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            icon: const UstaIcon(UstaIcons.directions, size: 22),
            label: const Text('Yol Tarifi'),
            onPressed: () async {
              final ok = await ref
                  .read(contactLauncherProvider)
                  .directions(
                    lat: usta.lat,
                    lng: usta.lng,
                    query: '${usta.businessName} ${usta.address}',
                  );
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harita uygulaması açılamadı.')),
                );
              }
            },
          ),
        ],
      ],
    );
  }
}

/// Pinned: one primary action (Ara) and one secondary (Mesaj Gönder → sheet).
/// On their own page an usta gets no "Ara / Mesaj Gönder": they see what customers see, and edit.
class _OwnerBar extends StatelessWidget {
  const _OwnerBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.ui.gutter,
            AppSpacing.md,
            context.ui.gutter,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu senin sayfan. Müşteriler böyle görüyor.',
                style: AppTypography.bodySm,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const UstaIcon(UstaIcons.pencil, size: 20),
                      label: const Text('Sayfamı düzenle'),
                      onPressed: () => context.go('/page'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const UstaIcon(UstaIcons.crown, size: 20),
                      label: const Text('Öne çık'),
                      onPressed: () => context.push('/promote'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.read(contactLauncherProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.ui.gutter,
            AppSpacing.md,
            context.ui.gutter,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: FilledButton.icon(
                  icon: const UstaIcon(UstaIcons.phone, size: 22),
                  label: const Text('Ara'),
                  onPressed: () async {
                    final ok = await launcher.call(usta.phoneNumber);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bu cihazdan arama başlatılamadı. Numara: ${formatPhone(usta.phoneNumber)}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 6,
                child: OutlinedButton.icon(
                  icon: const UstaIcon(UstaIcons.message, size: 22),
                  label: const Text('Mesaj Gönder'),
                  onPressed: () => showContactSheet(context, usta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.ui.gutter),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 92, height: 92, radius: 12),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 180, height: 22),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 16),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(width: 140, height: 18),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(height: 160, radius: 12),
          ],
        ),
      ),
    );
  }
}
