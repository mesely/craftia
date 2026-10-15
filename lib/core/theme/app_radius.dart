import 'package:flutter/widgets.dart';

/// A small radius vocabulary. Full "pill" shapes are intentionally not offered.
abstract final class AppRadius {
  /// Small controls, tags, thumbnails.
  static const double sm = 8;

  /// Buttons, inputs, ordinary surfaces.
  static const double md = 12;

  /// Major cards.
  static const double lg = 16;

  /// Bottom sheets.
  static const double xl = 24;

  static const borderSm = BorderRadius.all(Radius.circular(sm));
  static const borderMd = BorderRadius.all(Radius.circular(md));
  static const borderLg = BorderRadius.all(Radius.circular(lg));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}
