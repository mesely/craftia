import 'package:intl/intl.dart';

final NumberFormat _decimal = NumberFormat.decimalPattern('tr_TR');

/// "1.500 ₺" (Turkish convention: symbol after the amount).
String formatLira(num value) => '${_decimal.format(value.round())} ₺';

String formatNumber(num value) => _decimal.format(value);

/// "4,8"
String formatRating(double rating) =>
    rating.toStringAsFixed(1).replaceAll('.', ',');

/// Turkish date, e.g. "14 Ekim 2026".
String formatDate(DateTime date) =>
    DateFormat('d MMMM y', 'tr_TR').format(date);

/// Keeps digits and '+', for tel:/sms: URIs.
String sanitizePhone(String phone) => phone.replaceAll(RegExp(r'[^\d+]'), '');

/// "+905321234567" -> "0532 123 45 67"
String formatPhone(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('90') && digits.length == 12) {
    digits = '0${digits.substring(2)}';
  }
  if (digits.length == 11 && digits.startsWith('0')) {
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9)}';
  }
  return phone;
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  final first = parts.first.substring(0, 1);
  final second = parts.length > 1 ? parts[1].substring(0, 1) : '';
  return '$first$second'.toUpperCase();
}
