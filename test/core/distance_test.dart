import 'package:flutter_test/flutter_test.dart';
import 'package:usta/core/utils/distance.dart';

void main() {
  group('haversineKm', () {
    test('is zero for the same point', () {
      expect(haversineKm(41.0, 29.0, 41.0, 29.0), closeTo(0, 0.001));
    });

    test('Istanbul to Ankara is about 350 km', () {
      expect(
        haversineKm(41.0082, 28.9784, 39.9334, 32.8597),
        inInclusiveRange(340, 360),
      );
    });

    test('is symmetric', () {
      final a = haversineKm(38.4237, 27.1428, 36.8969, 30.7133);
      final b = haversineKm(36.8969, 30.7133, 38.4237, 27.1428);
      expect(a, closeTo(b, 1e-9));
    });
  });

  group('isValidCoordinate', () {
    test(
      'never treats (0,0) as a location',
      () => expect(isValidCoordinate(0, 0), isFalse),
    );
    test('rejects null, NaN and out-of-range', () {
      expect(isValidCoordinate(null, 29), isFalse);
      expect(isValidCoordinate(double.nan, 29), isFalse);
      expect(isValidCoordinate(95, 29), isFalse);
      expect(isValidCoordinate(41, 181), isFalse);
    });
    test(
      'accepts real coordinates',
      () => expect(isValidCoordinate(41.0, 29.0), isTrue),
    );
  });

  group('formatDistance', () {
    test('uses metres under 1 km', () => expect(formatDistance(0.85), '850 m'));
    test(
      'one decimal with Turkish comma under 10 km',
      () => expect(formatDistance(3.46), '3,5 km'),
    );
    test('rounds above 10 km', () => expect(formatDistance(12.4), '12 km'));
  });
}
