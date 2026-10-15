import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/constants/illustrations.dart';
import '../../core/constants/services.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/service_request.dart';
import '../auth/auth_controller.dart';
import 'requests_controller.dart';

enum RequestTab {
  fresh('Yeni'),
  active('Devam eden'),
  closed('Biten');

  const RequestTab(this.label);
  final String label;

  bool matches(ServiceRequest r) => switch (this) {
    RequestTab.fresh => r.status == RequestStatus.pending,
    RequestTab.active => r.status == RequestStatus.accepted,
    RequestTab.closed =>
      r.status == RequestStatus.completed ||
          r.status == RequestStatus.cancelled,
  };
}

class RequestTabController extends Notifier<RequestTab> {
  @override
  RequestTab build() => RequestTab.fresh;

  void select(RequestTab tab) => state = tab;
}

/// Which group of requests an usta is looking at.
final requestTabProvider = NotifierProvider<RequestTabController, RequestTab>(
  RequestTabController.new,
);

/// Taleplerim (usta: Talepler). Each request is a card named after *what was asked*, with a
/// plain-language status, the latest message and the two things people do next: write or call.
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final requests = ref.watch(requestsProvider);
    final gutter = context.ui.gutter;
    final title = auth.isProvider ? 'Talepler' : 'Taleplerim';
    final tab = ref.watch(requestTabProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(requestsProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.lg,
                gutter,
                AppSpacing.lg,
              ),
              child: Semantics(
                header: true,
                child: Text(title, style: AppTypography.display),
              ),
            ),
          ),
          if (auth.isProvider && (requests.value?.isNotEmpty ?? false))
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.lg),
                child: _TabBar(all: requests.value!, selected: tab),
              ),
            ),
          if (!auth.signedIn)
            SliverToBoxAdapter(
              child: StateView(
                illustration: Illustrations.emptyRequests,
                title: 'Taleplerini görmek için giriş yap',
                message: 'Ustalara talep gönder, yanıtları ve mesajları burada takip et.',
                actionLabel: 'Giriş yap',
                onAction: () => context.push('/login'),
              ),
            )
          else
            requests.when(
              loading: () =>
                  const SliverToBoxAdapter(child: _RequestsSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorStateView(
                  failure: AppFailure.from(e),
                  onRetry: () => ref.invalidate(requestsProvider),
                ),
              ),
              data: (all) {
                final items = auth.isProvider && all.isNotEmpty
                    ? all.where(tab.matches).toList()
                    : all;
                return items.isEmpty
                    ? SliverToBoxAdapter(
                        child: StateView(
                          illustration: Illustrations.emptyRequests,
                          title: auth.isProvider && all.isNotEmpty
                              ? 'Bu grupta talep yok'
                              : auth.isProvider
                              ? 'Henüz talep gelmedi'
                              : 'Henüz talebin yok',
                          message: auth.isProvider
                              ? 'Müşteriler sana talep gönderdiğinde burada göreceksin.'
                              : 'Bir ustanın sayfasında “Mesaj Gönder” dersen talebin burada görünür.',
                          actionLabel: auth.isProvider ? null : 'Usta bul',
                          onAction: auth.isProvider
                              ? null
                              : () => context.go('/'),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          0,
                          gutter,
                          AppSpacing.xxl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) => _RequestCard(
                            request: items[i],
                            viewerProviderId: auth.account?.providerId,
                          ),
                        ),
                      );
              },
            ),
        ],
      ),
    );
  }
}

/// Yeni / Devam eden / Biten, each with how many are inside: an usta reads their inbox by what needs doing.
class _TabBar extends ConsumerWidget {
  const _TabBar({required this.all, required this.selected});

  final List<ServiceRequest> all;
  final RequestTab selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        for (final t in RequestTab.values) ...[
          if (t != RequestTab.values.first)
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              button: true,
              selected: t == selected,
              label: '${t.label}, ${all.where(t.matches).length} talep',
              excludeSemantics: true,
              child: Material(
                color: t == selected
                    ? AppColors.primarySoft
                    : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMd,
                  side: t == selected
                      ? AppBorders.selected
                      : AppBorders.hairline,
                ),
                child: InkWell(
                  borderRadius: AppRadius.borderMd,
                  onTap: () => ref.read(requestTabProvider.notifier).select(t),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: context.ui.tapTarget + 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${all.where(t.matches).length}',
                            style: AppTypography.title.copyWith(
                              color: t == selected
                                  ? AppColors.primary
                                  : AppColors.ink,
                            ),
                          ),
                          Text(
                            t.label,
                            style: AppTypography.caption,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, required this.viewerProviderId});

  final ServiceRequest request;
  final String? viewerProviderId;

  Color get _statusColor => switch (request.status) {
    RequestStatus.pending => AppColors.amberInk,
    RequestStatus.accepted => AppColors.primary,
    RequestStatus.completed => AppColors.success,
    RequestStatus.cancelled => AppColors.inkMuted,
  };

  UstaIconData get _statusIcon => switch (request.status) {
    RequestStatus.pending => UstaIcons.clock,
    RequestStatus.accepted => UstaIcons.checkCircle,
    RequestStatus.completed => UstaIcons.verified,
    RequestStatus.cancelled => UstaIcons.closeCircle,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = request.isInboxFor(viewerProviderId);
    final other = request.otherName(viewerProviderId);
    final service =
        serviceFor(subType: request.subType)?.label ?? request.subType;
    final phone = inbox ? request.contactPhone : request.providerPhone;
    final when = request.lastMessageAt ?? request.createdAt;
    final preview = request.lastMessageText.isEmpty
        ? request.description
        : request.lastMessageText;
    final open = request.conversationId == null
        ? null
        : () => context.push('/chat/${request.conversationId}');

    return Semantics(
      container: true,
      label:
          '${request.title}. ${request.status.label(asProvider: inbox)}. '
          '${inbox ? 'Müşteri' : 'Usta'}: $other.'
          '${request.unread > 0 ? ' ${request.unread} yeni mesaj.' : ''}',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: request.unread > 0
              ? BorderSide(color: AppColors.primary, width: 1.5)
              : AppBorders.hairline,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: 2,
                  children: [
                    if (service.isNotEmpty)
                      Text(
                        service,
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UstaIcon(_statusIcon, size: 18, color: _statusColor),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            request.status.label(asProvider: inbox),
                            style: AppTypography.label.copyWith(
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // The request itself is the headline; the person is secondary.
                Text(
                  request.title,
                  style: AppTypography.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${inbox ? 'Müşteri' : 'Usta'}: $other',
                  style: AppTypography.body.copyWith(
                    color: AppColors.inkMuted,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: request.unread > 0
                              ? AppColors.ink
                              : AppColors.inkMuted,
                          fontWeight: request.unread > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(formatRelative(when), style: AppTypography.caption),
                  ],
                ),
                if (request.unread > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${request.unread} yeni mesaj',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    request.status.hint(asProvider: inbox),
                    style: AppTypography.bodySm,
                  ),
                ],
                if (inbox && request.status == RequestStatus.pending) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => ref
                              .read(requestsProvider.notifier)
                              .changeStatus(request.id, RequestStatus.accepted),
                          child: const Text('Kabul et'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref
                              .read(requestsProvider.notifier)
                              .changeStatus(
                                request.id,
                                RequestStatus.cancelled,
                              ),
                          child: const Text('Uygun değilim'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child:
                          (inbox && request.status == RequestStatus.pending
                          ? OutlinedButton.icon
                          : FilledButton.icon)(
                            icon: const UstaIcon(UstaIcons.message, size: 20),
                            label: const Text('Mesajlar'),
                            onPressed: open,
                          ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 5,
                        child: OutlinedButton.icon(
                          icon: const UstaIcon(UstaIcons.phone, size: 20),
                          label: Text(inbox ? 'Müşteriyi ara' : 'Ustayı ara'),
                          onPressed: () async {
                            final ok = await ref
                                .read(contactLauncherProvider)
                                .call(phone);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Arama başlatılamadı. Numara: ${formatPhone(phone)}',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestsSkeleton extends StatelessWidget {
  const _RequestsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.ui.gutter),
        child: const Column(
          children: [
            SkeletonBox(height: 200, radius: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 200, radius: 16),
          ],
        ),
      ),
    );
  }
}
