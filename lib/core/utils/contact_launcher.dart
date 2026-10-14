import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<bool> maps({double? lat, double? lng, String? query}) {
    final q = (lat != null && lng != null) ? '$lat,$lng' : (query ?? '');
    if (q.isEmpty) return Future.value(false);
    return _launch(
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': q}),
      mode: LaunchMode.externalApplication,
    );
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
