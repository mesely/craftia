import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class _Section {
  const _Section(this.heading, this.body);
  final String heading;
  final String body;
}

class _Document {
  const _Document(this.title, this.subtitle, this.sections, this.footer);
  final String title;
  final String subtitle;
  final List<_Section> sections;
  final String footer;
}

final _documents = <String, _Document>{
  'agreement': const _Document(
    'Kullanıcı sözleşmesi',
    'Mesafeli aracılık sözleşmesi',
    [
      _Section(
        '1. Aracı hizmet statüsü',
        'USTA, 6563 sayılı Kanun uyarınca bir “aracı hizmet sağlayıcı”dır. Platform, hizmet veren (usta) ile hizmet alanı buluşturur; sunulan hizmetin tarafı, bayisi veya işvereni değildir.',
      ),
      _Section(
        '2. Sorumluluk sınırı',
        'Hizmetin ifası sırasında oluşabilecek maddi zararlar, hatalı işçilik veya gecikmelerden doğrudan hizmet veren (usta) sorumludur. USTA bu uyuşmazlıklarda tazminat yükümlülüğü altında değildir.',
      ),
      _Section(
        '3. Ödeme ve komisyon',
        'Platform üzerinden yapılan ödemeler 6493 sayılı Kanun kapsamında lisanslı ödeme kuruluşları aracılığıyla yapılır. Elden yapılan ödemeler USTA güvencesi dışındadır ve takip edilemez.',
      ),
      _Section(
        '4. İptal ve cayma',
        'Hizmetin ifasına başlandıktan sonra cayma hakkı kullanılamaz. Randevuya 2 saatten az süre kala yapılan iptallerde “servis çağrı bedeli” iade edilmeyebilir.',
      ),
      _Section(
        '5. Uyuşmazlık',
        'Uyuşmazlıklarda her yıl belirlenen parasal sınırlar dahilinde Tüketici Hakem Heyetleri ve İstanbul Mahkemeleri yetkilidir.',
      ),
    ],
    'Uygulamayı kullanarak yukarıdaki şartları kabul etmiş sayılırsın.',
  ),
  'kvkk': _Document('KVKK aydınlatma metni', '6698 sayılı Kanun kapsamında', [
    const _Section(
      '1. Veri sorumlusu',
      'Kişisel verilerin, veri sorumlusu USTA Platform Teknolojileri A.Ş. tarafından güvenli altyapıda işlenmektedir.',
    ),
    const _Section(
      '2. İşlenen veriler',
      'Kimlik (ad, soyad), iletişim (telefon), konum (hizmet adresi ve cihaz konumu) ve güvenlik (IP, log) verileri işlenebilir. Cihaz konumun yalnızca yakındaki ustaları göstermek için kullanılır.',
    ),
    const _Section(
      '3. Veri aktarımı',
      'Verilerin yalnızca seçtiğin hizmet veren (usta) ile ve yasal zorunluluk hallerinde yetkili kamu kurumlarıyla paylaşılır.',
    ),
    _Section(
      '4. Başvuru ve bilgi',
      'Haklarını kullanmak için ${AppConfig.legalEmail} adresine yazabilirsin.',
    ),
  ], 'Son güncelleme: 12.02.2026'),
};

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key, required this.docId});

  final String docId;

  @override
  Widget build(BuildContext context) {
    final doc = _documents[docId];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(PhosphorIconsBold.arrowLeft),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: doc == null
          ? const Center(
              child: Text('Belge bulunamadı.', style: AppTypography.body),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.xxxl,
              ),
              children: [
                Text(doc.title, style: AppTypography.display),
                const SizedBox(height: AppSpacing.xs),
                Text(doc.subtitle, style: AppTypography.bodySm),
                for (final s in doc.sections) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(s.heading, style: AppTypography.titleSm),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    s.body,
                    style: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                Text(doc.footer, style: AppTypography.caption),
              ],
            ),
    );
  }
}
