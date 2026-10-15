import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/ui_scale.dart';
import '../../core/config/app_config.dart';
import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
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

const _updated = 'Son güncelleme: Ekim 2026';

final _documents = <String, _Document>{
  'agreement': const _Document(
    'Kullanıcı Sözleşmesi',
    'Usta’yı kullanmadan önce lütfen oku',
    [
      _Section(
        '1. Usta nedir?',
        'Usta, hizmet almak isteyenlerle (müşteri) hizmet vermek isteyenleri (usta) bir araya getiren bir ilan ve iletişim platformudur. Elektrik, su tesisatı, klima, boya gibi hizmetlerin tarafı, işvereni, temsilcisi ya da garantörü değildir.',
      ),
      _Section(
        '2. Platformun rolü',
        'Usta, 6563 sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun anlamında aracı hizmet sağlayıcı, 5651 sayılı Kanun anlamında yer sağlayıcıdır. Hizmet sözleşmesi yalnızca müşteri ile usta arasında kurulur.',
      ),
      _Section(
        '3. Uygulama sahibinin sorumluluğu',
        'Uygulamanın sahibi ve işleticisi; ustaların verdiği hizmetin kalitesinden, zamanında yapılmasından, fiyatından, verdiği zararlardan, kimlik ve belge doğruluğundan, ödeme ve tahsilat süreçlerinden; kullanıcılar arasında çıkan her türlü anlaşmazlıktan, dolandırıcılık dahil hukuka aykırı eylemlerden sorumlu değildir ve bu konularda taraf değildir. Hizmetin ve ödemenin tüm sorumluluğu ilgili kullanıcılara aittir. Emlak ve ikinci el ilan siteleri gibi, Usta yalnızca ilanın yayınlanmasına ve kullanıcıların iletişim kurmasına aracılık eder.',
      ),
      _Section(
        '4. Kullanıcı yükümlülükleri',
        'Doğru ve güncel bilgi vermeyi, başkası adına işlem yapmamayı, hukuka ve genel ahlaka aykırı içerik paylaşmamayı, diğer kullanıcılara saygılı davranmayı kabul edersin. İş başlamadan önce fiyatı ve kapsamı ustayla netleştirmek senin sorumluluğundadır.',
      ),
      _Section(
        '5. Ödeme',
        'Usta üzerinden ödeme alınmaz ve aracılık edilmez. Ödemeler müşteri ile usta arasında yapılır; fatura ve fiş düzenlemek ustanın yükümlülüğüdür. Usta, yapılan ödemelerin güvencesini vermez.',
      ),
      _Section(
        '6. Mesajlaşma ve kayıtlar',
        'Uygulama içi yazışmalar ve gönderilen fotoğraflar, anlaşmazlık ve güvenlik süreçlerinde kullanılmak üzere kayıt altında tutulur. Ayrıntılar KVKK Aydınlatma Metni’ndedir. Yazışmalar yalnızca sohbetin iki tarafı tarafından görülür.',
      ),
      _Section(
        '7. Şikayet ve kötüye kullanım',
        'Dolandırıcılık, tehdit, sahte bilgi gibi durumları uygulamadaki “Şikayet et” düğmesiyle bildirebilirsin. Şikayetler kayıt altına alınır; kuralları ihlal eden hesaplar uyarılmadan kısıtlanabilir veya kapatılabilir. Şikayet etmek, resmi mercilere başvurma hakkını ortadan kaldırmaz.',
      ),
      _Section(
        '8. Uyuşmazlıklar',
        'Müşteri ile usta arasındaki uyuşmazlıklar, kanunda belirtilen parasal sınırlar dahilinde Tüketici Hakem Heyetleri ve Tüketici Mahkemeleri ile diğer yetkili merciler önünde çözülür. Usta bu süreçlerde taraf değildir; talep edilirse yalnızca yetkili mercilere ilgili kayıtları sunar.',
      ),
    ],
    'Uygulamayı kullanarak bu şartları kabul etmiş sayılırsın. $_updated',
  ),
  'kvkk': _Document(
    'KVKK Aydınlatma Metni',
    '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında',
    [
      const _Section(
        '1. Veri sorumlusu',
        'Kişisel verilerin, Usta uygulamasının işleticisi olan veri sorumlusu tarafından işlenir. İletişim: ${AppConfig.legalEmail}',
      ),
      const _Section(
        '2. Hangi verileri işliyoruz?',
        'Kimlik ve iletişim (ad soyad, telefon, e-posta), hesap bilgileri, konum (yalnızca yakındaki ustaları göstermek için, izin verirsen), hizmet talepleri, uygulama içi mesajların ve gönderdiğin fotoğrafların içeriği, şikayet kayıtları ve güvenlik kayıtları (cihaz ve bağlantı bilgisi).',
      ),
      const _Section(
        '3. Neden işliyoruz?',
        'Hesabını oluşturmak, seni ustalarla buluşturmak ve yazışmanı sağlamak (sözleşmenin kurulması ve ifası); sahtekârlığı ve kötüye kullanımı önlemek, şikayetleri incelemek (meşru menfaat); yasal yükümlülükleri yerine getirmek; konum için açık rızan.',
      ),
      const _Section(
        '4. Mesajlar kayıt altında tutulur',
        'Uygulama içinde yaptığın tüm yazışmalar ve gönderdiğin fotoğraflar veritabanımızda saklanır. Bunlar yalnızca sohbetin iki tarafı tarafından görülür. Bir anlaşmazlık, dolandırıcılık şüphesi, şikayet veya hukuki talep olduğunda, ilgili kayıtlar sohbetin tarafları ile ve yetkili kamu kurumları ya da mahkemelerle paylaşılabilir. Bu nedenle uygulama içinde paylaşmak istemediğin bilgileri yazma.',
      ),
      const _Section(
        '5. Verilerin aktarılması',
        'Verilerin; seçtiğin usta ya da müşteri ile (yalnızca hizmet için gerekli ölçüde), altyapı ve barındırma hizmeti aldığımız tedarikçilerle ve yasal zorunluluk halinde yetkili kurumlarla paylaşılabilir. Verilerin satılmaz.',
      ),
      const _Section(
        '6. Ne kadar saklıyoruz?',
        'Hesabın açık olduğu sürece. Hesabını sildiğinde kimlik bilgilerin kaldırılır; anlaşmazlık ve güvenlik süreçleri için mesaj ve şikayet kayıtları, kimliği kaldırılmış şekilde yasal zamanaşımı süresince saklanır.',
      ),
      const _Section(
        '7. Haklarını nasıl kullanırsın?',
        'KVKK’nın 11. maddesi uyarınca verilerinin işlenip işlenmediğini öğrenme, bilgi isteme, düzeltme, silme, itiraz etme haklarına sahipsin. Uygulamadan: Ayarlar > Verilerimi indir (tüm verilerini dosya olarak al) ve Ayarlar > Hesabımı sil. Ayrıca ${AppConfig.legalEmail} adresine yazabilir ya da Kişisel Verileri Koruma Kurumu’na başvurabilirsin.',
      ),
    ],
    _updated,
  ),
  'disclaimer': const _Document(
    'Sorumluluk Reddi',
    'Platformun rolü ve sınırları',
    [
      _Section(
        'Usta bir aracıdır',
        'Usta, ustalarla müşterileri tanıştırır. İşi ustalar yapar; fiyatı ve şartları taraflar belirler. Uygulama sahibi hizmetin tarafı değildir.',
      ),
      _Section(
        'Sorumluluk kullanıcılardadır',
        'İşin kalitesi, gecikme, zarar, yanlış ya da eksik bilgi, ödeme sorunları, anlaşmazlıklar ve dolandırıcılık gibi durumlarda sorumluluk ilgili kullanıcılara aittir. Uygulama sahibi bu konularda sorumluluk kabul etmez, tazminat ya da iade yükümlülüğü altında değildir.',
      ),
      _Section(
        'Doğrulanmış ne demek?',
        '“Doğrulanmış” etiketi, ustanın temel bilgilerinin kontrol edildiği anlamına gelir; işin kalitesinin ya da güvenliğinin garantisi değildir. “Öne çıkan” etiketi ise ilanın listede öne çıkarıldığını gösterir, kalite belgesi değildir.',
      ),
      _Section(
        'Ne yapabilirsin?',
        'İş başlamadan önce fiyatı netleştir, yorumlara bak, mümkünse ödemeyi iş bittikten sonra yap. Bir sorun yaşarsan uygulamadan şikayet et ve gerekiyorsa resmi mercilere (Tüketici Hakem Heyeti, Polis 155) başvur.',
      ),
    ],
    _updated,
  ),
  'safety': const _Document(
    'Güvenli İletişim Rehberi',
    'Dolandırıcılığa karşı kısa ipuçları',
    [
      _Section(
        'Ödemeyi dikkatli yap',
        'İş yapılmadan büyük miktarda ön ödeme ya da “kapora” isteyen kişilere dikkat et. Mümkünse ödemeyi iş bittikten sonra yap ve makbuz iste.',
      ),
      _Section(
        'Bilgilerini koru',
        'Şifreni, banka kartı bilgini, SMS ile gelen kodları kimseyle paylaşma. Usta hiçbir zaman senden bu bilgileri istemez.',
      ),
      _Section(
        'Ustayı tanı',
        'Profildeki yorumlara, puana ve iş fotoğraflarına bak. Çok düşük fiyat teklifleri ve acele ettirmeler uyarı işaretidir.',
      ),
      _Section(
        'Şüphelenirsen',
        'Yazışmayı uygulama içinde sürdür; çünkü kayıt altında kalır. Şüpheli bir durumda “Şikayet et” düğmesini kullan, tehdit ya da dolandırıcılık varsa 155’i ara.',
      ),
    ],
    _updated,
  ),
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
          icon: const UstaIcon(UstaIcons.arrowLeft, size: 26),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
        ),
      ),
      body: doc == null
          ? Center(child: Text('Belge bulunamadı.', style: AppTypography.body))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                context.ui.gutter,
                0,
                context.ui.gutter,
                AppSpacing.xxxl,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(doc.title, style: AppTypography.display),
                ),
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
