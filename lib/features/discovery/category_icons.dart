import '../../core/icons/usta_icons.dart';

/// The symbol for a whole category (home tiles, fallback).
UstaIconData categoryIcon(String? id) => switch (id) {
  'TECHNICAL' => UstaIcons.bolt,
  'CONSTRUCTION' => UstaIcons.brickWall,
  'CLIMATE' => UstaIcons.climate,
  'TECH' => UstaIcons.monitor,
  'LIFE' => UstaIcons.broom,
  null => UstaIcons.grid,
  _ => UstaIcons.toolbox,
};

/// Lower-case, ASCII-only form of Turkish text ("Çilingir" -> "cilingir") for keyword matching.
String foldTurkish(String s) {
  const map = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ç': 'c',
    'ç': 'c',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
  };
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    b.write(map[ch] ?? ch.toLowerCase());
  }
  return b.toString();
}

/// The symbol for one service (sub-type): a klima gets an air conditioner, a petek a radiator,
/// never a generic thermometer. Matching is by keyword so legacy spellings in the database still work.
/// Unknown services fall back to their category's symbol.
UstaIconData serviceIcon({String? mainType, String? subType}) {
  final t = foldTurkish(subType ?? '');
  const rules = <(String, UstaIconData)>[
    ('elektrik', UstaIcons.plug),
    ('tesisat', UstaIcons.droplet),
    ('cilingir', UstaIcons.key),
    ('kamera', UstaIcons.camera),
    ('alarm', UstaIcons.camera),
    ('boya', UstaIcons.roller),
    ('dekorasyon', UstaIcons.sofa),
    ('marangoz', UstaIcons.hammer),
    ('elektronik', UstaIcons.tv),
    ('alcipan', UstaIcons.plasterboard),
    ('parke', UstaIcons.parquet),
    ('fayans', UstaIcons.tile),
    ('seramik', UstaIcons.tile),
    ('kombi', UstaIcons.boiler),
    ('klima', UstaIcons.airConditioner),
    ('petek', UstaIcons.radiator),
    ('beyaz esya', UstaIcons.washingMachine),
    ('camasir', UstaIcons.washingMachine),
    ('buzdolabi', UstaIcons.washingMachine),
    ('tv', UstaIcons.tv),
    ('televizyon', UstaIcons.tv),
    ('laptop', UstaIcons.laptop),
    ('bilgisayar', UstaIcons.laptop),
    ('ilaclama', UstaIcons.sprayCan),
    ('koltuk', UstaIcons.sofa),
    ('temizlik', UstaIcons.bucket),
  ];
  for (final (keyword, icon) in rules) {
    if (t.contains(keyword)) return icon;
  }
  return categoryIcon(mainType);
}
