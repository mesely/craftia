import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/ui_scale.dart';
import '../core/accessibility/ui_scale_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import 'router.dart';

class UstaApp extends ConsumerStatefulWidget {
  const UstaApp({super.key});

  @override
  ConsumerState<UstaApp> createState() => _UstaAppState();
}

class _UstaAppState extends ConsumerState<UstaApp> with WidgetsBindingObserver {
  Brightness? _applied;

  /// Colours are plain reads from [AppColors], not inherited, so a palette switch has to
  /// rebuild every widget, including `const` ones and pages kept alive in other tabs.
  static void _markNeedsBuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_markNeedsBuild);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// "Telefon varsayılanı" follows the phone live, including the evening switch to dark.
  @override
  void didChangePlatformBrightness() {
    if (ref.read(themeModeProvider) == AppThemeMode.system) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(uiScaleProvider);
    final mode = ref.watch(themeModeProvider);
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = mode.resolve(platform);
    // Colours are read from [AppColors] while widgets build, so the palette is switched
    // first, and the whole tree below is marked dirty when the brightness changes.
    AppColors.apply(brightness);
    if (_applied != null && _applied != brightness) {
      (context as Element).visitChildren(_markNeedsBuild);
    }
    _applied = brightness;
    return MaterialApp.router(
      title: 'Usta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(scale.metrics, brightness: brightness),
      themeMode: ThemeMode.light,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // The OS font size is respected and multiplied by the Usta UI size.
        final system = media.textScaler.scale(100) / 100;
        final dark = brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: UiScaleScope(
            scale: scale,
            child: MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  effectiveTextScale(system: system, scale: scale),
                ),
              ),
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
