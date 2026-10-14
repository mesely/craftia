import 'package:flutter_test/flutter_test.dart';
import 'package:usta/data/models/provider_application.dart';
import 'package:usta/data/models/service_price.dart';

void main() {
  group('ServicePrice.parseRange', () {
    test(
      'min-max',
      () => expect(ServicePrice.parseRange('100-200'), (100.0, 200.0)),
    );
    test(
      'Turkish thousands separators',
      () =>
          expect(ServicePrice.parseRange('1.500 - 2.000 ₺'), (1500.0, 2000.0)),
    );
    test(
      'single value is exact',
      () => expect(ServicePrice.parseRange('750'), (750.0, 750.0)),
    );
    test('numbers', () => expect(ServicePrice.parseRange(850), (850.0, 850.0)));
    test('malformed values become missing', () {
      expect(ServicePrice.parseRange('Arayınız'), (null, null));
      expect(ServicePrice.parseRange(''), (null, null));
      expect(ServicePrice.parseRange(null), (null, null));
    });
    test(
      'reversed range is swapped',
      () => expect(ServicePrice.parseRange('500-300'), (300.0, 500.0)),
    );
  });

  group('ServicePrice.parseList', () {
    test('structured list', () {
      final list = ServicePrice.parseList([
        {'serviceName': 'Boya', 'minPrice': 5000, 'maxPrice': 6000},
      ]);
      expect(
        list.single,
        const ServicePrice(serviceName: 'Boya', minPrice: 5000, maxPrice: 6000),
      );
    });

    test('legacy map', () {
      final list = ServicePrice.parseList({
        'Ampul': '100-200',
        'Keşif': 'Arayınız',
        '': '5',
      });
      expect(list.length, 2);
      expect(list.first.minPrice, 100);
      expect(list.last.hasPrice, isFalse);
    });

    test('garbage input yields an empty list', () {
      expect(ServicePrice.parseList(null), isEmpty);
      expect(ServicePrice.parseList('x'), isEmpty);
      expect(ServicePrice.parseList([1, 'a']), isEmpty);
    });
  });

  group('priceLabel', () {
    test(
      'range',
      () => expect(
        const ServicePrice(
          serviceName: 'a',
          minPrice: 1500,
          maxPrice: 2000,
        ).priceLabel,
        '1.500 – 2.000 ₺',
      ),
    );
    test(
      'exact',
      () => expect(
        const ServicePrice(
          serviceName: 'a',
          minPrice: 750,
          maxPrice: 750,
        ).priceLabel,
        '750 ₺',
      ),
    );
    test(
      'missing',
      () => expect(
        const ServicePrice(serviceName: 'a').priceLabel,
        'Fiyat için arayın',
      ),
    );
  });

  group('validatePriceRange (original x2 / x1.5 / x1.3 rule)', () {
    test('accepts values within the ceiling', () {
      expect(validatePriceRange(1000, 2000), isNull);
      expect(validatePriceRange(5000, 7500), isNull);
      expect(validatePriceRange(20000, 26000), isNull);
    });
    test('rejects values above the ceiling', () {
      expect(validatePriceRange(1000, 2001), contains('2000'));
      expect(validatePriceRange(5000, 7600), isNotNull);
    });
    test('rejects max below min and missing values', () {
      expect(validatePriceRange(500, 400), isNotNull);
      expect(validatePriceRange(null, 400), isNotNull);
    });
  });
}
