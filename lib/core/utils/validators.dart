/// Form checks with plain Turkish messages. Each returns null when the value is fine.
abstract final class Validators {
  static String? name(String? v) {
    final t = (v ?? '').trim();
    if (t.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length < 2 ||
        t.length < 5) {
      return 'Lütfen adını ve soyadını yaz.';
    }
    return null;
  }

  static String? businessName(String? v) =>
      (v ?? '').trim().length < 3 ? 'Usta veya işletme adını yaz.' : null;

  /// Turkish mobile numbers: 5XX XXX XX XX, with or without 0 / +90.
  static String? phone(String? v) {
    var digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return RegExp(r'^5\d{9}$').hasMatch(digits)
        ? null
        : 'Telefon numaranı 05XX XXX XX XX biçiminde yaz.';
  }

  static String? email(String? v) {
    final t = (v ?? '').trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(t)
        ? null
        : 'E-posta adresini kontrol et. Örnek: ad@ornek.com';
  }

  static String? password(String? v) =>
      (v ?? '').length < 6 ? 'Şifren en az 6 karakter olmalı.' : null;

  static String? required(String? v, String message, {int min = 2}) =>
      (v ?? '').trim().length < min ? message : null;
}
