import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:usta/core/utils/formatters.dart';
import 'package:usta/data/models/service_request.dart';

ServiceRequest request(String description, {String status = 'PENDING'}) =>
    ServiceRequest.fromJson({
      'id': 'r1',
      'providerId': 'p1',
      'providerName': 'Ali Elektrik',
      'subType': 'Elektrikçi',
      'city': 'İzmir',
      'description': description,
      'status': status,
      'createdAt': '2026-10-14T10:00:00.000Z',
      'customerName': 'Ayşe',
    });

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('request title', () {
    test('is the first sentence of what the customer wrote', () {
      expect(
        request('Mutfaktaki priz çalışmıyor. Dün akşam başladı.').title,
        'Mutfaktaki priz çalışmıyor.',
      );
    });

    test('long text is cut at a word boundary with an ellipsis', () {
      final title = request(
        'Salonun tavanında su lekesi oluştu ve boyanın dökülmeye başladığını fark ettim lütfen bakar mısınız',
      ).title;
      expect(title.endsWith('…'), isTrue);
      expect(title.length <= 58, isTrue);
      expect(title.contains('  '), isFalse);
    });
  });

  group('status wording', () {
    test('customers read "Ustaya iletildi", ustas read "Yeni talep"', () {
      final r = request('Priz bozuk, bakar mısınız?');
      expect(r.status.label(), 'Ustaya iletildi');
      expect(r.status.label(asProvider: true), 'Yeni talep');
      expect(RequestStatus.accepted.label(), 'Usta kabul etti');
      expect(RequestStatus.completed.label(), 'Tamamlandı');
      expect(RequestStatus.cancelled.label(), 'İptal edildi');
    });

    test('every status explains what happens next', () {
      for (final s in RequestStatus.values) {
        expect(s.hint(), isNotEmpty);
        expect(s.hint(asProvider: true), isNotEmpty);
      }
    });
  });

  group('viewer', () {
    test('the other person is the usta for a customer and the customer for an usta', () {
      final r = request('Priz bozuk, bakar mısınız?');
      expect(r.otherName(null), 'Ali Elektrik');
      expect(r.otherName('p1'), 'Ayşe');
      expect(r.isInboxFor('p1'), isTrue);
      expect(r.isInboxFor('other'), isFalse);
    });
  });

  group('time labels', () {
    final now = DateTime(2026, 10, 15, 12);
    test('today shows the clock, yesterday says Dün', () {
      expect(formatRelative(DateTime(2026, 10, 15, 9, 5), now: now), '09:05');
      expect(formatRelative(DateTime(2026, 10, 14, 23), now: now), 'Dün');
      expect(formatDayLabel(DateTime(2026, 10, 15), now: now), 'Bugün');
      expect(formatDayLabel(DateTime(2026, 10, 14), now: now), 'Dün');
    });
  });
}
