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
              data: (items) => items.isEmpty
                  ? SliverToBoxAdapter(
                      child: StateView(
                        illustration: Illustrations.emptyRequests,
                        title: auth.isProvider
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
                    ),
            ),
        ],
      ),
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
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: FilledButton.icon(
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
