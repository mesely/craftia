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
