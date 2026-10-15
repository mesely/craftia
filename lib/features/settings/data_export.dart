import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/app_failure.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';

/// "Verilerimi indir": fetches everything stored about the signed-in person and hands it to the
/// system share sheet as a JSON file (save to Files, send by mail, …). KVKK access/portability right.
Future<void> exportMyData(BuildContext context, WidgetRef ref) async {
  final account = ref.read(authProvider).account;
  final messenger = ScaffoldMessenger.of(context);
  if (account == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Verilerini indirmek için önce giriş yapmalısın.'),
      ),
    );
    return;
  }
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Verilerin hazırlanıyor…'),
      duration: Duration(seconds: 2),
    ),
  );
  try {
    final data = await ref
        .read(accountsRepositoryProvider)
        .exportData(account.id);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/usta-verilerim-$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    messenger.hideCurrentSnackBar();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Usta verilerim',
      ),
    );
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(AppFailure.from(e).message)));
  }
}
