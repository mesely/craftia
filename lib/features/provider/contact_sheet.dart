import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/choice_tile.dart';
import '../../data/models/service_request.dart';
import '../../data/models/usta.dart';
import '../auth/ensure_signed_in.dart';
import '../orders/requests_controller.dart';
import 'request_sheet.dart';

/// "Mesaj Gönder": the ways to write to an usta, grouped so the detail page keeps one clear
/// primary action ("Ara"). Writing inside the app is first, because it keeps a record of what
/// was agreed; WhatsApp and SMS are there for people who prefer them.
Future<void> showContactSheet(BuildContext context, Usta usta) => showAppSheet(
  context,
  builder: (_) => _ContactSheet(usta: usta, parentContext: context),
);

class _ContactSheet extends ConsumerWidget {
  const _ContactSheet({required this.usta, required this.parentContext});

  final Usta usta;

  /// The page behind the sheet: still alive after the sheet closes, so it can open the next one.
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = context.ui.gutter;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final launcher = ref.read(contactLauncherProvider);

    Future<void> writeInApp() async {
      navigator.pop();
      if (!parentContext.mounted) return;
      if (!await ensureSignedIn(
        parentContext,
        ref,
        reason: 'Ustaya uygulamadan yazmak için hesabına giriş yapmalısın.',
      )) {
        return;
      }
      // One open conversation per usta: continue it instead of starting a second one.
      final open = ref
          .read(requestsProvider)
          .value
          ?.where(
            (r) =>
                r.providerId == usta.id &&
                r.conversationId != null &&
                (r.status == RequestStatus.pending ||
                    r.status == RequestStatus.accepted),
          )
          .firstOrNull;
      if (open != null) {
        if (parentContext.mounted) {
          parentContext.push('/chat/${open.conversationId}');
        }
        return;
      }
      if (!parentContext.mounted) return;
      final created = await showRequestSheet(parentContext, usta);
      if (created?.conversationId != null && parentContext.mounted) {
        parentContext.push('/chat/${created!.conversationId}');
      }
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(usta.businessName, subtitle: 'Nasıl yazmak istersin?'),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxl),
            child: Column(
              children: [
                ChoiceTile(
                  leading: UstaIcons.requests,
                  label: 'Uygulamadan yaz',
                  caption: 'Talebin kayıt altında kalır',
                  selected: false,
                  onTap: writeInApp,
                ),
                const SizedBox(height: AppSpacing.sm),
                ChoiceTile(
                  leading: UstaIcons.message,
                  label: 'WhatsApp’tan yaz',
                  caption: 'Uygulama dışında, kayıt tutulmaz',
                  selected: false,
                  onTap: () async {
                    navigator.pop();
                    final ok = await launcher.whatsapp(
                      usta.phoneNumber,
                      text:
                          'Merhaba, Usta uygulamasında ${usta.businessName} sayfanızı gördüm.',
                    );
                    if (!ok) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('WhatsApp açılamadı.')),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ChoiceTile(
                  leading: UstaIcons.phone,
                  label: 'SMS ile yaz',
                  caption: 'Telefonundaki mesaj uygulaması açılır',
                  selected: false,
                  onTap: () async {
                    navigator.pop();
                    final ok = await launcher.sms(usta.phoneNumber);
                    if (!ok) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Mesaj uygulaması açılamadı. Numara: ${formatPhone(usta.phoneNumber)}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
