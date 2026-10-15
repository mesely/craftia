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
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/service_request.dart';
import '../../data/models/usta.dart';
import '../auth/auth_controller.dart';
import '../discovery/discovery_providers.dart';
import '../orders/requests_controller.dart';
import 'profile_completeness.dart';
import 'studio_widgets.dart';

/// Home for an usta: what needs an answer now, how the page is doing, and what would help most.
/// Customers never see this; they get the search page on the same tab.
class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider.select((s) => s.account));
    final providerId = account?.providerId;
    final gutter = context.ui.gutter;
    if (account == null || providerId == null) return const SizedBox.shrink();

    final usta = ref.watch(ustaDetailProvider(providerId));
    final requests = ref.watch(requestsProvider).value ?? const [];
    final inbox = requests.where((r) => r.isInboxFor(providerId)).toList();
    final waiting = inbox
        .where((r) => r.status == RequestStatus.pending)
        .toList();
    final unread = inbox.fold<int>(0, (sum, r) => sum + r.unread);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ustaDetailProvider(providerId));
        await ref.read(requestsProvider.notifier).refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          gutter,
          AppSpacing.lg,
          gutter,
          AppSpacing.xxxl,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Merhaba, ${account.firstName}',
              style: AppTypography.display,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            waiting.isEmpty
                ? 'Bekleyen talebin yok.'
                : waiting.length == 1
                ? '1 yeni talep seni bekliyor.'
                : '${waiting.length} yeni talep seni bekliyor.',
            style: AppTypography.body.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          usta.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorStateView(
              failure: AppFailure.from(e),
              onRetry: () => ref.invalidate(ustaDetailProvider(providerId)),
            ),
            data: (u) => _Body(usta: u, waiting: waiting, unread: unread),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.usta,
    required this.waiting,
    required this.unread,
  });

  final Usta usta;
  final List<ServiceRequest> waiting;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final completeness = ProfileCompleteness.of(usta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  value: '${waiting.length}',
                  label: 'Yeni talep',
                  highlight: waiting.isNotEmpty,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  value: '$unread',
                  label: 'Yeni mesaj',
                  highlight: unread > 0,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  value: usta.hasRating ? formatRating(usta.rating) : '–',
                  label: usta.reviewCount > 0
                      ? '${usta.reviewCount} yorum'
                      : 'Puan',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (waiting.isNotEmpty) ...[
          Text('Yanıt bekleyenler', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          for (final r in waiting.take(3)) ...[
            _WaitingRequest(request: r),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (waiting.length > 3)
            TextButton(
              onPressed: () => context.go('/requests'),
              child: Text('Tümünü gör (${waiting.length})'),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _PromotionCard(usta: usta),
        const SizedBox(height: AppSpacing.xxl),
        if (!completeness.complete) ...[
          Row(
            children: [
              Expanded(
                child: Text('Sayfanı tamamla', style: AppTypography.title),
              ),
              Text(
                '${completeness.doneCount}/${completeness.items.length}',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.borderSm,
            child: LinearProgressIndicator(
              value: completeness.fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StudioCard(
            child: Column(
              children: [
                for (final item in completeness.items)
                  StudioRow(
                    icon: switch (item.id) {
                      'photo' => UstaIcons.photoCamera,
                      'about' => UstaIcons.pencil,
                      'prices' => UstaIcons.document,
                      'work' => UstaIcons.image,
                      _ => UstaIcons.pin,
                    },
                    title: item.title,
                    caption: item.done ? null : item.hint,
                    done: item.done,
                    onTap: () => context.go('/page'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        StudioCard(
          child: StudioRow(
            icon: UstaIcons.user,
            title: 'Müşteri gözüyle sayfam',
            caption: 'Sayfanın müşterilere nasıl göründüğüne bak',
            onTap: () => context.push('/usta/${usta.id}', extra: usta),
          ),
        ),
      ],
    );
  }
}

class _WaitingRequest extends ConsumerWidget {
  const _WaitingRequest({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StudioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.title,
            style: AppTypography.titleSm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${request.customerName.isEmpty ? 'Müşteri' : request.customerName} · ${formatRelative(request.createdAt)}',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(requestsProvider.notifier)
                          .changeStatus(request.id, RequestStatus.accepted);
                      if (context.mounted && request.conversationId != null) {
                        context.push('/chat/${request.conversationId}');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppFailure.from(e).message)),
                        );
                      }
                    }
                  },
                  child: const Text('Kabul et'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: request.conversationId == null
                      ? null
                      : () => context.push('/chat/${request.conversationId}'),
                  child: const Text('Mesajı aç'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.usta});

  final Usta usta;

  @override
  Widget build(BuildContext context) {
    final until = usta.featuredUntil;
    final running = until != null && until.isAfter(DateTime.now());
    return StudioCard(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UstaIcon(UstaIcons.crown, size: 26, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  running ? 'Öne çıkanlardasın' : 'Öne çık, daha çok iş al',
                  style: AppTypography.titleSm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            running
                ? '${formatDate(until)} tarihine kadar aramaların en üstünde görünüyorsun.'
                : 'Aramalarda en üstte, “Öne çıkan” etiketiyle görün. 1 hafta, 1 ay ya da 3 ay seç.',
            style: AppTypography.body.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.push('/promote'),
            child: Text(running ? 'Süreyi uzat' : 'Planları gör'),
          ),
        ],
      ),
    );
  }
}
