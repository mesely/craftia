import 'package:flutter/widgets.dart';

/// The in-app "Arayüz Boyutu" setting. It scales text, touch targets and key
/// spacing together. It is applied *on top of* the operating system's own font
/// scaling, never instead of it.
enum UiScale {
  normal('normal', 'Normal', 'Çoğu kişi için dengeli boyut.', UiMetrics.normal),
  large('large', 'Büyük', 'Yazılar ve düğmeler daha büyük.', UiMetrics.large),
  extraLarge(
    'extra_large',
    'Çok büyük',
    'En rahat okunan boyut.',
    UiMetrics.extraLarge,
  );

  const UiScale(this.storageKey, this.label, this.description, this.metrics);

  final String storageKey;
  final String label;
  final String description;
  final UiMetrics metrics;

  static UiScale fromStorage(String? key) => UiScale.values.firstWhere(
    (s) => s.storageKey == key,
    orElse: () => UiScale.normal,
  );
}

/// Size tokens that change with [UiScale]. Colours, radii and type styles are
/// shared; only dimensions people have to *hit* or *read* grow.
@immutable
class UiMetrics {
  const UiMetrics({
    required this.textFactor,
    required this.tapTarget,
    required this.buttonHeight,
    required this.rowHeight,
    required this.navHeight,
    required this.gutter,
    required this.avatar,
  });

  /// Multiplied with the OS text scale (see `UstaApp`).
  final double textFactor;

  /// Minimum size of any tappable control.
  final double tapTarget;

  /// Primary and secondary button height.
  final double buttonHeight;

  /// Minimum height of list rows / form fields.
  final double rowHeight;

  final double navHeight;

  /// Horizontal page padding.
  final double gutter;

  /// Avatar size in provider lists.
  final double avatar;

  static const normal = UiMetrics(
    textFactor: 1,
    tapTarget: 48,
    buttonHeight: 52,
    rowHeight: 56,
    navHeight: 68,
    gutter: 20,
    avatar: 72,
  );
  static const large = UiMetrics(
    textFactor: 1.18,
    tapTarget: 56,
    buttonHeight: 58,
    rowHeight: 64,
    navHeight: 76,
    gutter: 20,
    avatar: 76,
  );
  static const extraLarge = UiMetrics(
    textFactor: 1.36,
    tapTarget: 64,
    buttonHeight: 64,
    rowHeight: 72,
    navHeight: 84,
    gutter: 24,
    avatar: 80,
  );
}

/// Combines the OS text scale with the Usta UI size. Capped so an extreme
/// combination can still lay out, but the cap is well above Android's maximum.
double effectiveTextScale({required double system, required UiScale scale}) =>
    (system * scale.metrics.textFactor).clamp(0.85, 2.4);

class UiScaleScope extends InheritedWidget {
  const UiScaleScope({super.key, required this.scale, required super.child});

  final UiScale scale;

  static UiMetrics metricsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<UiScaleScope>()
          ?.scale
          .metrics ??
      UiMetrics.normal;

  static UiScale of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UiScaleScope>()?.scale ??
      UiScale.normal;

  @override
  bool updateShouldNotify(UiScaleScope old) => scale != old.scale;
}

extension UiContext on BuildContext {
  UiMetrics get ui => UiScaleScope.metricsOf(this);
}
