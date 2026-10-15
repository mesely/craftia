import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/constants/illustrations.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/service_request.dart';
import '../auth/auth_controller.dart';
import '../orders/requests_controller.dart';

/// Bildirimler: conversations that have something new, newest first.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(requestsProvider);
    final viewerProviderId = ref.watch(
      authProvider.select((s) => s.account?.providerId),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ErrorStateView(
            failure: AppFailure.from(e),
            onRetry: () => ref.invalidate(requestsProvider),
          ),
        ),
        data: (items) {
          final fresh = items.where((r) => r.unread > 0).toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(requestsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                context.ui.gutter,
                0,
                context.ui.gutter,
                AppSpacing.xxl,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text('Bildirimler', style: AppTypography.display),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (fresh.isEmpty)
                  const StateView(
                    illustration: Illustrations.emptyRequests,
                    title: 'Yeni bildirimin yok',
                    message: 'Biri sana yazdığında burada göreceksin.',
                  )
                else
                  for (final r in fresh) ...[
                    _NotificationTile(
                      request: r,
                      viewerProviderId: viewerProviderId,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.request,
    required this.viewerProviderId,
  });

  final ServiceRequest request;
  final String? viewerProviderId;

  @override
  Widget build(BuildContext context) {
    final who = request.otherName(viewerProviderId);
    final when = request.lastMessageAt ?? request.createdAt;
    return Semantics(
      button: true,
      label: '$who sana yazdı: ${request.lastMessageText}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: AppBorders.hairline,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderMd,
          onTap: request.conversationId == null
              ? null
              : () => context.push('/chat/${request.conversationId}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UstaIcon(UstaIcons.message, size: 26, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$who sana yazdı', style: AppTypography.titleSm),
                      const SizedBox(height: 2),
                      Text(
                        request.lastMessageText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.inkMuted,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(formatRelative(when), style: AppTypography.bodySm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
