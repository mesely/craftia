import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/ui_scale.dart';
import '../core/accessibility/ui_scale_controller.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class UstaApp extends ConsumerWidget {
  const UstaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);
    return MaterialApp.router(
      title: 'Usta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(scale.metrics),
      themeMode: ThemeMode.light,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // The OS font size is respected and multiplied by the Usta UI size.
        final system = media.textScaler.scale(100) / 100;
        return UiScaleScope(
          scale: scale,
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                effectiveTextScale(system: system, scale: scale),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
