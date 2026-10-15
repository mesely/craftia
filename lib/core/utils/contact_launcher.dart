import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'distance.dart';
import 'formatters.dart';

/// Native call / SMS / maps / mail launching. Every method returns false instead of throwing
/// (simulators and tablets often cannot place calls).
class ContactLauncher {
  const ContactLauncher();

  Future<bool> call(String phone) =>
      _launch(Uri(scheme: 'tel', path: sanitizePhone(phone)));

  Future<bool> sms(String phone) =>
      _launch(Uri(scheme: 'sms', path: sanitizePhone(phone)));

  Future<bool> mail(String to, {String? subject, String? body}) => _launch(
    Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {'subject': ?subject, 'body': ?body},
    ),
  );

  /// Universal Google Maps directions URL; the phone hands it to whichever maps app it prefers.
  /// Null when there is neither a valid coordinate nor a text destination.
  static Uri? directionsUri({double? lat, double? lng, String? query}) {
    final destination = isValidCoordinate(lat, lng)
        ? '$lat,$lng'
        : (query ?? '').trim();
    if (destination.isEmpty) return null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
  }

  Future<bool> directions({double? lat, double? lng, String? query}) {
    final uri = directionsUri(lat: lat, lng: lng, query: query);
    if (uri == null) return Future.value(false);
    return _launch(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens a web page in the browser (official application pages, etc.).
  Future<bool> openUrl(String url) =>
      _launch(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// "05321234567" / "+90 532 123 45 67" -> "905321234567", or null when it is not a usable number.
  static String? whatsappNumber(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = '90${digits.substring(1)}';
    } else if (digits.length == 10 && digits.startsWith('5')) {
      digits = '90$digits';
    }
    return digits.length >= 11 && digits.length <= 15 ? digits : null;
  }

  /// Universal WhatsApp link: opens the app when installed, otherwise WhatsApp Web / the store page.
  static Uri? whatsappUri(String phone, {String? text}) {
    final number = whatsappNumber(phone);
    if (number == null) return null;
    return Uri.https('wa.me', '/$number', {
      if (text != null && text.isNotEmpty) 'text': text,
    });
  }

  Future<bool> whatsapp(String phone, {String? text}) {
    final uri = whatsappUri(phone, text: text);
    if (uri == null) return Future.value(false);
    return _launch(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}

final contactLauncherProvider = Provider<ContactLauncher>(
  (ref) => const ContactLauncher(),
);
