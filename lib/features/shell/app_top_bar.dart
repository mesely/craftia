import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/network_image.dart';
import '../auth/auth_controller.dart';
import '../discovery/discovery_providers.dart';
import '../orders/requests_controller.dart';

/// Always on top of the main tabs: the brand on the left; notifications and the profile button
/// on the right, in the same place on every screen so they are easy to find and to hit.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider.select((s) => s.account));
    final unread = ref.watch(unreadCountProvider);
    final gutter = context.ui.gutter;
    // With very large text the wordmark gives way, so the actions never get squeezed.
    final compact = MediaQuery.textScalerOf(context).scale(16) > 20;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.xs,
        account == null ? gutter : gutter - 6,
        0,
      ),
      child: SizedBox(
        height: context.ui.tapTarget + 8,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: Image.asset(
                'assets/brand/logo_mark.webp',
                width: 32,
                height: 32,
                cacheWidth: 96,
                excludeFromSemantics: true,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Usta',
                style: AppTypography.title.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (account == null)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      // Its text ends exactly at the page margin, like "Değiştir" below.
                      padding: const EdgeInsets.only(left: 12),
                      alignment: Alignment.centerRight,
                    ),
                    onPressed: () => context.push('/login'),
                    child: const Text(
                      'Giriş yap',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            else ...[
              const Spacer(),
              _BellButton(unread: unread),
              const SizedBox(width: AppSpacing.xs),
              _ProfileButton(
                initials: _initials(account.name),
                providerId: account.providerId,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final a = parts.first.substring(0, 1);
    final b = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$a$b'.toUpperCase();
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    final box = context.ui.tapTarget;
    return Semantics(
      button: true,
      label: unread > 0 ? 'Bildirimler, $unread yeni mesaj' : 'Bildirimler',
      excludeSemantics: true,
      child: InkResponse(
        radius: box / 2,
        onTap: () => context.push('/notifications'),
        child: SizedBox.square(
          dimension: box,
          child: Stack(
            alignment: Alignment.center,
            children: [
              UstaIcon(UstaIcons.bell, size: 26, color: AppColors.ink),
              if (unread > 0)
                Positioned(
                  top: box * 0.14,
                  right: box * 0.10,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
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

class _ProfileButton extends ConsumerWidget {
  const _ProfileButton({required this.initials, this.providerId});

  final String initials;
  final String? providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = context.ui.tapTarget;
    // An usta shows their own profile photo; everyone else shows their initials.
    final photo = providerId == null
        ? null
        : ref.watch(ustaDetailProvider(providerId!)).value?.profileImage;
    return Semantics(
      button: true,
      label: 'Profilim',
      excludeSemantics: true,
      child: InkResponse(
        radius: box / 2,
        onTap: () => context.push('/profile'),
        child: SizedBox.square(
          dimension: box,
          child: Center(
            child: Container(
              width: box - 10,
              height: box - 10,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.borderMd,
                border: Border.fromBorderSide(
                  AppBorders.hairline.copyWith(color: AppColors.primary),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: photo != null
                  ? AppNetworkImage(
                      url: photo,
                      width: box - 10,
                      height: box - 10,
                      cacheWidth: 160,
                    )
                  : Text(
                      initials,
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
