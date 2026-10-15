import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('name needs a first and a last name', () {
      expect(Validators.name('Ayşe'), isNotNull);
      expect(Validators.name('A B'), isNotNull);
      expect(Validators.name('Ayşe Yılmaz'), isNull);
    });

    test('Turkish mobile numbers in every common spelling', () {
      for (final ok in [
        '05321234567',
        '0532 123 45 67',
        '+90 532 123 45 67',
        '5321234567',
        '905321234567',
      ]) {
        expect(Validators.phone(ok), isNull, reason: ok);
      }
      for (final bad in ['', '0212 123 45 67', '12345', '0532 123 45']) {
        expect(Validators.phone(bad), isNotNull, reason: bad);
      }
    });

    test('e-mail and password', () {
      expect(Validators.email('ad@ornek.com'), isNull);
      expect(Validators.email('ad@ornek'), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });
}
