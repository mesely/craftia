import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/contact_launcher.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  static const _topics = [
    'Randevuya gelmedi',
    'Fiyat uyuşmazlığı',
    'Kötü işçilik / eksik hizmet',
    'Güvenlik / kaba davranış',
    'Teknik hata / uygulama çökmesi',
    'Ödeme / fatura sorunu',
    'Kişisel veri / gizlilik talebi',
    'Öneri veya geri bildirim',
  ];

  final _message = TextEditingController();
  String? _topic;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final ok = await ref
        .read(contactLauncherProvider)
        .mail(
          AppConfig.supportEmail,
          subject: '[Usta] ${_topic ?? 'Destek'}',
          body: _message.text.trim(),
        );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-posta uygulaması açılamadı. Bize ${AppConfig.supportEmail} adresinden yazabilirsin.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.xxxl,
        ),
        children: [
          const Text('Destek', style: AppTypography.display),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Sorununu seç, kısaca anlat; e-posta olarak ekibimize iletelim.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.xxl),
          DropdownButtonFormField<String>(
            initialValue: _topic,
            isExpanded: true,
            hint: const Text('Konu seç'),
            items: [
              for (final t in _topics)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _topic = v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _message,
            minLines: 5,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Ne oldu? Mümkünse usta adını ve tarihi de yaz.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _topic != null && _message.text.trim().length >= 10
                ? _send
                : null,
            child: const Text('E-posta olarak gönder'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Usta, bağımsız hizmet verenlerle kullanıcıları buluşturan bir platformdur. Hizmet kusurlarında Tüketici Hakem Heyeti’ne başvurma hakkın saklıdır.',
            style: AppTypography.caption.copyWith(color: AppColors.inkSubtle),
          ),
        ],
      ),
    );
  }
}
