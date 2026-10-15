import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/constants/services.dart';
import 'package:usta/features/chat/quick_replies.dart';
import 'package:usta/features/discovery/service_art.dart';

void main() {
  group('serviceFor', () {
    test('matches the legacy lower-case values stored in the database', () {
      expect(serviceFor(subType: 'elektrikçi')?.id, 'elektrik');
      expect(serviceFor(subType: 'su tesisatçısı')?.id, 'su');
      expect(serviceFor(subType: 'klima ve kombi servisi')?.id, 'klima');
      expect(serviceFor(subType: 'boyacı')?.id, 'boya');
      expect(serviceFor(subType: 'beyaz eşya tamiri')?.id, 'beyaz-esya');
      expect(serviceFor(subType: 'ev temizliği')?.id, 'temizlik');
    });

    test('tolerates other spellings by keyword', () {
      expect(serviceFor(subType: 'Petek Temizliği')?.id, 'klima');
      expect(serviceFor(subType: 'TV Tamiri')?.id, 'elektronik');
      expect(serviceFor(subType: 'bilinmeyen')?.id, isNull);
    });

    test('every service has its own illustration', () {
      final art = kServices.map((s) => s.art).toSet();
      expect(art.length, kServices.length);
    });

    test('art lookup falls back to the category, then nothing', () {
      expect(
        serviceArtAsset(subType: 'elektrikçi'),
        'assets/services/elektrik.webp',
      );
      expect(
        serviceArtAsset(mainType: 'LIFE', subType: 'bilinmeyen'),
        'assets/services/temizlik.webp',
      );
      expect(serviceArtAsset(subType: 'bilinmeyen'), isNull);
    });
  });

  group('quick replies', () {
    test('differ by side and by kind of work', () {
      final customer = quickReplies(asProvider: false, subType: 'Boyacı');
      final provider = quickReplies(asProvider: true, subType: 'Boyacı');
      expect(customer, isNot(equals(provider)));
      expect(
        customer.any((t) => t.contains('Metrekareyi')),
        isTrue,
        reason: 'construction suggestions mention the size of the job',
      );
      expect(
        quickReplies(
          asProvider: false,
          subType: 'Elektrikçi',
        ).any((t) => t.contains('Arıza')),
        isTrue,
      );
    });
  });
}
