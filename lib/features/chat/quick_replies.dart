import '../../core/constants/services.dart';

/// "Hazır mesajlar": one tap puts a sensible sentence in the box, ready to edit. Written per side
/// (customer / usta) and per kind of work, so the suggestions match what people actually need.
List<String> quickReplies({required bool asProvider, required String subType}) {
  final family = serviceFor(subType: subType)?.mainType;
  if (asProvider) {
    return [
      'Merhaba, talebinizi aldım. Size yardımcı olabilirim.',
      'Ne zaman uygun olursunuz? Gün ve saat yazar mısınız?',
      'Daha net fiyat için sorunun fotoğrafını gönderebilir misiniz?',
      'Keşif için adresinizi paylaşır mısınız?',
      'Yaklaşık fiyat: … ₺ (işin kapsamına göre değişebilir).',
      ...switch (family) {
        'TECHNICAL' => [
          'Güvenliğiniz için arızalı hattın sigortasını kapatmanızı öneririm.',
        ],
        'CONSTRUCTION' => [
          'Metrekareyi ve oda sayısını yazar mısınız? Ona göre fiyat vereyim.',
        ],
        'TECH' => ['Cihazın marka ve modelini yazar mısınız?'],
        'LIFE' => ['Evin büyüklüğünü ve kat bilgisini yazar mısınız?'],
        _ => const <String>[],
      },
      'Yoldayım, yaklaşık 20 dakikaya oradayım.',
      'İş tamamlandı. Bir sorun olursa yazabilirsiniz.',
    ];
  }
  return [
    'Merhaba, ne zaman gelebilirsiniz?',
    'Yaklaşık fiyatı öğrenebilir miyim?',
    'Fotoğraf gönderiyorum, bakabilir misiniz?',
    'Adresimi paylaşıyorum.',
    ...switch (family) {
      'TECHNICAL' => [
        'Arıza bir süredir var, acil. Bugün gelebilir misiniz?',
        'Sorunun fotoğrafını göndereyim mi?',
      ],
      'CONSTRUCTION' => [
        'Metrekareyi ve oda sayısını yazayım, keşfe gelebilir misiniz?',
        'Malzemeyi siz mi getirirsiniz?',
      ],
      'TECH' => [
        'Cihazın marka ve modelini yazayım mı?',
        'Tamir ücretini önceden öğrenebilir miyim?',
      ],
      'LIFE' => ['Evim 3+1, fiyat alabilir miyim?', 'Hangi gün müsaitsiniz?'],
      _ => const <String>[],
    },
    'Teşekkürler, size döneceğim.',
  ];
}
