import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/errors/app_failure.dart';
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
import '../../data/models/review.dart';
import '../../data/models/usta.dart';
import '../discovery/discovery_providers.dart';
import '../location/location_controller.dart';
import '../reviews/review_sheet.dart';
import '../reviews/reviews_controller.dart';
import 'image_viewer.dart';
import 'request_sheet.dart';
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
      icon: const Icon(PhosphorIconsBold.arrowLeft),
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

    return Scaffold(
      appBar: AppBar(leading: const _BackButton()),
      bottomNavigationBar: _ActionBar(usta: usta),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.xxxl,
        ),
        children: [
          _Identity(usta: usta),
          const SizedBox(height: AppSpacing.xl),
          _Stats(usta: usta, distance: distance, hasLocation: location != null),
          if (usta.about.isNotEmpty) ...[
            const _SectionTitle('Hakkında'),
            Text(usta.about, style: AppTypography.body),
          ],
          const _SectionTitle('Fiyat listesi'),
          _PriceList(usta: usta),
          const _SectionTitle('Yapılan işler'),
          _Portfolio(images: usta.portfolioImages),
          _ReviewsSection(usta: usta),
          const _SectionTitle('Adres'),
          _AddressCard(usta: usta),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTypography.title),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UstaAvatar(usta: usta, size: 72),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usta.businessName,
                style: AppTypography.title.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(usta.subType, style: AppTypography.bodySm),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  if (usta.isVerified)
                    const _Badge(
                      icon: PhosphorIconsFill.sealCheck,
                      label: 'Doğrulanmış',
                      color: AppColors.primary,
                    ),
                  if (usta.isPremium) const FeaturedLabel(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon + text, no filled background.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.usta,
    required this.distance,
    required this.hasLocation,
  });

  final Usta usta;
  final double? distance;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    final price = usta.startingPrice;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Puan',
                value: RatingLabel(
                  rating: usta.rating,
                  reviewCount: 0,
                  large: true,
                ),
                caption: usta.reviewCount > 0
                    ? '${usta.reviewCount} yorum'
                    : 'Henüz yorum yok',
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _Stat(
                label: 'Mesafe',
                value: Text(
                  distance != null ? formatDistance(distance!) : '—',
                  style: AppTypography.label,
                ),
                caption: distance != null
                    ? 'Sana uzaklık'
                    : (hasLocation ? 'Konum yok' : 'Konum izni yok'),
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _Stat(
                label: 'Başlangıç',
                value: Text(
                  price != null ? formatLira(price) : '—',
                  style: AppTypography.label,
                ),
                caption: price != null ? 'En düşük fiyat' : 'Fiyat için arayın',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final Widget value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          value,
          const SizedBox(height: 2),
          Text(
            caption,
            style: AppTypography.caption.copyWith(color: AppColors.inkSubtle),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PriceList extends StatelessWidget {
  const _PriceList({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context) {
    if (usta.priceList.isEmpty) {
      return const _InlineEmpty(
        icon: PhosphorIconsRegular.receipt,
        text: 'Bu usta henüz fiyat listesi eklememiş. Net fiyat için arayabilirsin.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < usta.priceList.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      usta.priceList[i].serviceName,
                      style: AppTypography.body,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    usta.priceList[i].priceLabel,
                    style: usta.priceList[i].hasPrice
                        ? AppTypography.label
                        : AppTypography.bodySm,
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Portfolio extends StatelessWidget {
  const _Portfolio({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _InlineEmpty(
        icon: PhosphorIconsRegular.image,
        text: 'Henüz iş fotoğrafı eklenmemiş.',
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => Semantics(
          button: true,
          label:
              'İş fotoğrafı ${i + 1} / ${images.length}. Büyütmek için dokun',
          child: GestureDetector(
            onTap: () => openImageViewer(context, images, i),
            child: AppNetworkImage(
              url: images[i],
              width: 186,
              height: 140,
              cacheWidth: 420,
              borderRadius: AppRadius.borderMd,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.inkSubtle),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTypography.bodySm)),
        ],
      ),
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
        icon: PhosphorIconsRegular.chatCircleText,
        text: 'Henüz yorum yok. Bu ustayla çalıştıysan ilk yorumu sen yaz.',
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in state.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ReviewTile(review: r),
            ),
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
            top: AppSpacing.xxl,
            bottom: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    state.total > 0 ? 'Yorumlar (${state.total})' : 'Yorumlar',
                    style: AppTypography.title,
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                label: const Text('Yorum yaz'),
                onPressed: () async {
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.authorName, style: AppTypography.label),
              ),
              RatingLabel(rating: review.rating, reviewCount: 0),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            formatDate(review.createdAt),
            style: AppTypography.caption.copyWith(color: AppColors.inkSubtle),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.comment, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = usta.address.isNotEmpty ? usta.address : usta.locationLabel;
    final canOpenMap = usta.hasCoordinates || address.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                PhosphorIconsFill.mapPin,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  address.isEmpty ? 'Adres bilgisi eklenmemiş.' : address,
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
          if (canOpenMap) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              icon: const Icon(PhosphorIconsRegular.mapTrifold, size: 20),
              label: const Text('Haritada aç'),
              onPressed: () async {
                final ok = await ref
                    .read(contactLauncherProvider)
                    .maps(
                      lat: usta.lat,
                      lng: usta.lng,
                      query: '${usta.businessName} $address',
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
          ],
        ],
      ),
    );
  }
}

/// Pinned primary actions: call, message, request.
class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.usta});

  final Usta usta;

  Future<void> _launch(
    BuildContext context,
    Future<bool> Function() action,
    String failure,
  ) async {
    final ok = await action();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.read(contactLauncherProvider);
    final unavailable =
        'Bu cihazdan başlatılamadı. Numara: ${formatPhone(usta.phoneNumber)}';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  icon: const Icon(PhosphorIconsFill.phone, size: 20),
                  label: const Text('Ara'),
                  onPressed: () => _launch(
                    context,
                    () => launcher.call(usta.phoneNumber),
                    unavailable,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 52,
                child: Semantics(
                  button: true,
                  label: 'Mesaj gönder',
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _launch(
                      context,
                      () => launcher.sms(usta.phoneNumber),
                      unavailable,
                    ),
                    child: const Icon(PhosphorIconsRegular.chatText, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed: () async {
                    final sent = await showRequestSheet(context, usta);
                    if (sent == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Talebin iletildi. Taleplerim sekmesinden takip edebilirsin.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Talep gönder'),
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
    return const SkeletonScope(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 72, height: 72, radius: 20),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 180, height: 20),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(height: 80, radius: 12),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(height: 160, radius: 16),
          ],
        ),
      ),
    );
  }
}
