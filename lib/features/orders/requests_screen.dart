import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/illustrations.dart';
import '../../core/accessibility/ui_scale.dart';
import '../../core/errors/app_failure.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/service_request.dart';
import 'requests_controller.dart';

/// "Taleplerim": service requests sent from this device.
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(requestsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(requestsProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.ui.gutter,
                    AppSpacing.lg,
                    context.ui.gutter,
                    AppSpacing.lg,
                  ),
                  child: const Text('Taleplerim', style: AppTypography.display),
                ),
              ),
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
                          title: 'Henüz talebin yok',
                          message: 'Bir ustanın sayfasında “Mesaj Gönder” dersen talebini burada takip edebilirsin.',
                          actionLabel: 'Usta bul',
                          onAction: () => context.go('/'),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          context.ui.gutter,
                          0,
                          context.ui.gutter,
                          AppSpacing.xxl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) =>
                              _RequestCard(request: items[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label:
          '${request.providerName ?? request.subType}, ${request.status.label}',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: AppBorders.hairline,
        ),
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: () => showAppSheet(
            context,
            builder: (_) => _RequestDetailSheet(request: request),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.providerName ??
                            (request.subType.isNotEmpty
                                ? request.subType
                                : 'Hizmet talebi'),
                        style: AppTypography.titleSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusPill(status: request.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  request.description,
                  style: AppTypography.body.copyWith(
                    color: AppColors.inkMuted,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${request.city} · ${formatDate(request.createdAt)}',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + words in the status colour: understandable without relying on colour.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color fg, UstaIconData icon) = switch (status) {
      RequestStatus.pending => (AppColors.amberInk, UstaIcons.clock),
      RequestStatus.accepted => (AppColors.primary, UstaIcons.checkCircle),
      RequestStatus.completed => (AppColors.success, UstaIcons.verified),
      RequestStatus.cancelled => (AppColors.danger, UstaIcons.closeCircle),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UstaIcon(icon, size: 18, color: fg),
        const SizedBox(width: AppSpacing.xs),
        Text(status.label, style: AppTypography.label.copyWith(color: fg)),
      ],
    );
  }
}

class _RequestDetailSheet extends ConsumerStatefulWidget {
  const _RequestDetailSheet({required this.request});

  final ServiceRequest request;

  @override
  ConsumerState<_RequestDetailSheet> createState() =>
      _RequestDetailSheetState();
}

class _RequestDetailSheetState extends ConsumerState<_RequestDetailSheet> {
  bool _busy = false;

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await ref.read(requestsProvider.notifier).cancel(widget.request.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppFailure.from(e).message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.ui.gutter,
        0,
        context.ui.gutter,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.providerName ?? 'Hizmet talebi',
                  style: AppTypography.title,
                ),
              ),
              _StatusPill(status: r.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${r.city} · ${formatDate(r.createdAt)}',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(r.description, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xl),
          if (r.providerId != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/usta/${r.providerId}');
                },
                child: const Text('Ustanın sayfasını aç'),
              ),
            ),
          if (r.status == RequestStatus.pending) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: _busy ? null : _cancel,
                child: Text(_busy ? 'İptal ediliyor…' : 'Talebi iptal et'),
              ),
            ),
          ],
        ],
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
            SkeletonBox(height: 92, radius: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 92, radius: 16),
          ],
        ),
      ),
    );
  }
}
