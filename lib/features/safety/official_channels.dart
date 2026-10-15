import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/contact_launcher.dart';

class _Channel {
  const _Channel(this.title, this.caption, this.action, {required this.isCall});
  final String title;
  final String caption;
  final String action; // URL or phone number
  final bool isCall;
}

const _channels = <_Channel>[
  _Channel(
    'e-Devlet · Tüketici Hakem Heyeti',
    'Fiyat ve hizmet uyuşmazlıkları için resmi başvuru.',
    'https://www.turkiye.gov.tr',
    isCall: false,
  ),
  _Channel(
    'T.C. Ticaret Bakanlığı · Tüketici',
    'Tüketici hakları ve şikayet başvurusu.',
    'https://tuketici.ticaret.gov.tr',
    isCall: false,
  ),
  _Channel(
    'ALO 175 · Tüketici Hattı',
    'Hakların hakkında ücretsiz bilgi al.',
    '175',
    isCall: true,
  ),
  _Channel(
    'Polis İmdat · 155',
    'Dolandırıcılık, tehdit ve acil durumlar.',
    '155',
    isCall: true,
  ),
  _Channel(
    'Emniyet Genel Müdürlüğü',
    'Siber suç ve dolandırıcılık bildirimi.',
    'https://www.egm.gov.tr',
    isCall: false,
  ),
  _Channel(
    'KVKK Kurumu',
    'Kişisel verilerinle ilgili şikayet ve başvuru.',
    'https://www.kvkk.gov.tr',
    isCall: false,
  ),
];

/// Official, state-run channels for disputes and fraud. Usta is only an intermediary, so these are
/// the places where a dispute is actually resolved.
class OfficialChannels extends ConsumerWidget {
  const OfficialChannels({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launcher = ref.read(contactLauncherProvider);
    return Column(
      children: [
        for (final c in _channels) ...[
          Semantics(
            button: true,
            label: '${c.title}. ${c.caption}',
            excludeSemantics: true,
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
                side: AppBorders.hairline,
              ),
              child: InkWell(
                borderRadius: AppRadius.borderMd,
                onTap: () async {
                  final ok = c.isCall
                      ? await launcher.call(c.action)
                      : await launcher.openUrl(c.action);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Açılamadı. ${c.action}')),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      UstaIcon(
                        c.isCall ? UstaIcons.phone : UstaIcons.directions,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title, style: AppTypography.titleSm),
                            const SizedBox(height: 2),
                            Text(c.caption, style: AppTypography.bodySm),
                          ],
                        ),
                      ),
                      UstaIcon(
                        UstaIcons.chevronRight,
                        size: 20,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
