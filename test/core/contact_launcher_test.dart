import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/utils/contact_launcher.dart';

void main() {
  group('directions', () {
    test('uses coordinates when valid', () {
      final uri = ContactLauncher.directionsUri(lat: 38.42, lng: 27.14)!;
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['destination'], '38.42,27.14');
    });

    test('never treats (0,0) as a place; falls back to the address text', () {
      final uri = ContactLauncher.directionsUri(
        lat: 0,
        lng: 0,
        query: 'Moda Cd. No:1 Kadıköy',
      )!;
      expect(uri.queryParameters['destination'], 'Moda Cd. No:1 Kadıköy');
    });

    test('nothing to navigate to -> null', () {
      expect(ContactLauncher.directionsUri(), isNull);
    });
  });

  group('WhatsApp', () {
    test('normalises Turkish numbers to international form', () {
      expect(ContactLauncher.whatsappNumber('0532 123 45 67'), '905321234567');
      expect(
        ContactLauncher.whatsappNumber('+90 532 123 45 67'),
        '905321234567',
      );
      expect(ContactLauncher.whatsappNumber('5321234567'), '905321234567');
    });

    test('rejects numbers that cannot be dialled', () {
      expect(ContactLauncher.whatsappNumber('123'), isNull);
      expect(ContactLauncher.whatsappUri('abc'), isNull);
    });

    test('builds the universal wa.me link with an optional text', () {
      final uri = ContactLauncher.whatsappUri('05321234567', text: 'Merhaba')!;
      expect(uri.host, 'wa.me');
      expect(uri.path, '/905321234567');
      expect(uri.queryParameters['text'], 'Merhaba');
    });
  });
}
