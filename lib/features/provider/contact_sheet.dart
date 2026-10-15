import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/choice_tile.dart';
import '../../data/models/usta.dart';
import 'request_sheet.dart';

/// "Mesaj Gönder": the two ways to write to an usta, grouped so the detail page
/// keeps a single clear primary action ("Ara").
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

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(
            usta.businessName,
            subtitle: 'Nasıl iletişime geçmek istersin?',
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxl),
            child: Column(
              children: [
                ChoiceTile(
                  leading: UstaIcons.requests,
                  label: 'Hizmet talebi gönder',
                  caption: 'İhtiyacını yaz, usta seni arasın',
                  selected: false,
                  onTap: () async {
                    navigator.pop();
                    if (!parentContext.mounted) return;
                    final sent = await showRequestSheet(parentContext, usta);
                    if (sent == true) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Talebin iletildi. Taleplerim sekmesinden takip edebilirsin.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ChoiceTile(
                  leading: UstaIcons.message,
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
