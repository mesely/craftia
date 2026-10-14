import 'package:flutter/widgets.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

IconData categoryIcon(String id, {bool filled = false}) => switch (id) {
  'TECHNICAL' =>
    filled ? PhosphorIconsFill.wrench : PhosphorIconsRegular.wrench,
  'CONSTRUCTION' =>
    filled ? PhosphorIconsFill.paintRoller : PhosphorIconsRegular.paintRoller,
  'CLIMATE' =>
    filled
        ? PhosphorIconsFill.thermometerSimple
        : PhosphorIconsRegular.thermometerSimple,
  'TECH' => filled ? PhosphorIconsFill.monitor : PhosphorIconsRegular.monitor,
  'LIFE' => filled ? PhosphorIconsFill.broom : PhosphorIconsRegular.broom,
  _ => filled ? PhosphorIconsFill.toolbox : PhosphorIconsRegular.toolbox,
};
