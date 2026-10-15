/// One glyph of the Usta icon family.
///
/// Every icon is drawn on a 24×24 grid with the same construction rules:
/// 2 px round-cap strokes, 2 px inner padding, 2 px corner radii, no fills
/// (except [filled] glyphs such as the rating star). [path] is SVG path data.
class UstaIconData {
  const UstaIconData(this.path, {this.filled = false});

  final String path;
  final bool filled;
}

abstract final class UstaIcons {
  // Navigation
  static const home = UstaIconData(
    'M3.5 11L12 4l8.5 7 M5.5 9.5V19a1 1 0 0 0 1 1h11a1 1 0 0 0 1-1V9.5 M10 20v-5.5h4V20',
  );
  static const requests = UstaIconData(
    'M9 3.5h6a1 1 0 0 1 1 1V6.5H8V4.5a1 1 0 0 1 1-1z M8 5H6.5A1.5 1.5 0 0 0 5 6.5V20a1.5 1.5 0 0 0 1.5 1.5h11A1.5 1.5 0 0 0 19 20V6.5A1.5 1.5 0 0 0 17.5 5H16 M8.5 12h7 M8.5 16h5',
  );
  static const user = UstaIconData(
    'M12 12a4 4 0 1 0 0-8a4 4 0 0 0 0 8z M4.5 20.5c.8-3.7 3.6-5.5 7.5-5.5s6.7 1.8 7.5 5.5',
  );

  // Actions
  static const search = UstaIconData(
    'M11 4a7 7 0 1 0 0 14a7 7 0 0 0 0-14z M16.2 16.2L21 21',
  );
  static const phone = UstaIconData(
    'M5.2 4.2L8 3.5a1.2 1.2 0 0 1 1.4.7l1.2 3a1.2 1.2 0 0 1-.4 1.4L8.800 9.700a12.500 12.500 0 0 0 5.500 5.500l1.100-1.400a1.200 1.200 0 0 1 1.400-.4l3 1.200a1.200 1.200 0 0 1 .7 1.400l-.7 2.800a1.800 1.800 0 0 1-1.800 1.400C10.800 20.200 3.800 13.200 3.800 6a1.800 1.800 0 0 1 1.400-1.800z',
  );
  static const message = UstaIconData(
    'M5 4.5h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-7.500L7 21v-3.500H5a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2z M7.500 9.500h9 M7.500 13h5.500',
  );
  static const directions = UstaIconData(
    'M20.500 3.500L3.500 10.200l7 2.800l2.800 7z',
  );
  static const sliders = UstaIconData(
    'M4 7h9 M17 7h3 M15 4.500v5 M4 17h3 M11 17h9 M9 14.500v5',
  );
  static const locate = UstaIconData(
    'M12 8a4 4 0 1 0 0 8a4 4 0 0 0 0-8z M12 2.500v3 M12 18.500v3 M2.500 12h3 M18.500 12h3',
  );
  static const pencil = UstaIconData(
    'M4 20l.8-4L16.500 4.300a1.800 1.800 0 0 1 2.500 0l.7.7a1.800 1.800 0 0 1 0 2.500L8 19.200z M14.500 6.500l3 3',
  );
  static const trash = UstaIconData(
    'M4 7h16 M9 7V4.500h6V7 M6.500 7l.8 12.500h9.400L17.500 7 M10 11v5 M14 11v5',
  );
  static const plus = UstaIconData('M12 5v14 M5 12h14');
  static const close = UstaIconData('M6 6l12 12 M18 6L6 18');
  static const check = UstaIconData('M5 12.500l4.500 4.500L19 7.500');

  // Arrows
  static const arrowLeft = UstaIconData('M19 12H5 M11 6l-6 6l6 6');
  static const arrowRight = UstaIconData('M5 12h14 M13 6l6 6l-6 6');
  static const chevronRight = UstaIconData('M9 5l7 7l-7 7');
  static const chevronDown = UstaIconData('M5 9l7 7l7-7');

  // Status and trust
  static const pin = UstaIconData(
    'M12 21c0 0-7-5.600-7-11a7 7 0 0 1 14 0c0 5.400-7 11-7 11z M12 7.500a2.500 2.500 0 1 0 0 5a2.500 2.500 0 0 0 0-5z',
  );
  static const star = UstaIconData(
    'M12 2.800L14.410 9.080L21.130 9.430L15.900 13.670L17.640 20.170L12 16.500L6.360 20.170L8.100 13.670L2.870 9.430L9.590 9.080z',
    filled: true,
  );
  static const starOutline = UstaIconData(
    'M12 2.800L14.410 9.080L21.130 9.430L15.900 13.670L17.640 20.170L12 16.500L6.360 20.170L8.100 13.670L2.870 9.430L9.590 9.080z',
  );
  static const verified = UstaIconData(
    'M12 3l7.500 2.800v5.700c0 4.600-3.100 8.200-7.500 9.500c-4.400-1.300-7.500-4.900-7.500-9.500V5.800L12 3z M8.500 12l2.500 2.500l4.500-5',
  );
  static const shield = UstaIconData(
    'M12 3l7.500 2.800v5.700c0 4.600-3.100 8.200-7.500 9.500c-4.400-1.300-7.500-4.900-7.500-9.500V5.800L12 3z',
  );
  static const checkCircle = UstaIconData(
    'M12 3a9 9 0 1 0 0 18a9 9 0 0 0 0-18z M8 12.500l2.800 2.800L16.200 9.500',
  );
  static const closeCircle = UstaIconData(
    'M12 3a9 9 0 1 0 0 18a9 9 0 0 0 0-18z M9 9l6 6 M15 9l-6 6',
  );
  static const clock = UstaIconData(
    'M12 3a9 9 0 1 0 0 18a9 9 0 0 0 0-18z M12 7v5l3 2',
  );
  static const warning = UstaIconData(
    'M12 3.500L21.500 20h-19z M12 10v4.500 M12 17.200v.1',
  );
  static const help = UstaIconData(
    'M12 3a9 9 0 1 0 0 18a9 9 0 0 0 0-18z M9.500 9.500a2.500 2.500 0 1 1 3.700 2.200c-.8.5-1.200 1-1.200 2 M12 16.800v.1',
  );

  // Content
  static const image = UstaIconData(
    'M5 4h14a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z M4 16l4.500-4.500l4 4l2.500-2.500L20 17 M15.500 7.500a1.500 1.500 0 1 0 0 3a1.500 1.500 0 0 0 0-3z',
  );
  static const document = UstaIconData(
    'M6 3h8l5 5v12a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z M14 3v5h5 M8.500 13h7 M8.500 17h5',
  );
  static const chart = UstaIconData('M5 20V11 M12 20V4 M19 20v-6 M3 20h18');
  static const textSize = UstaIconData(
    'M3 19L8 6l5 13 M4.800 14.500h6.400 M15.500 19l2.500-6.500l2.500 6.500 M16.300 17h3.400',
  );

  // Service categories
  static const grid = UstaIconData(
    'M5 4h5v5H5z M14 4h5v5h-5z M5 13h5v5H5z M14 13h5v5h-5z',
  );
  static const bolt = UstaIconData('M13 2.500L5 13.500h6l-1 8L19 10h-6z');
  static const roller = UstaIconData(
    'M5 4h12a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z M18 6.500h2.500v4.500H12v3 M10.500 14h3v7h-3z',
  );

  /// Warm and cool air: the "İklimlendirme" category as a whole (no thermometer).
  static const climate = UstaIconData(
    'M3 8c2-2.500 4-2.500 6 0s4 2.500 6 0 4-2.500 6 0 M3 13c2-2.500 4-2.500 6 0s4 2.500 6 0 4-2.500 6 0 M3 18c2-2.500 4-2.500 6 0s4 2.500 6 0 4-2.500 6 0',
  );
  static const monitor = UstaIconData(
    'M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z M9 20h6 M12 16v4',
  );
  static const broom = UstaIconData(
    'M12 3v7 M8 10h8l2 4.500H6z M8.500 14.500V21 M12 14.500V21 M15.500 14.500V21',
  );
  static const toolbox = UstaIconData('M4 8h16v11H4z M9 8V5.500h6V8 M4 13h16');

  // Individual services: one unmistakable object each.
  static const brickWall = UstaIconData(
    'M3 5h18v14H3z M3 9.700h18 M3 14.300h18 M9 5v4.700 M15 9.700v4.600 M9 14.300V19',
  );
  static const plug = UstaIconData(
    'M9 3v5 M15 3v5 M6 8h12v3a6 6 0 0 1-12 0z M12 17v4',
  );
  static const droplet = UstaIconData(
    'M12 3.500c3 3.800 6 6.700 6 10.500a6 6 0 0 1-12 0c0-3.800 3-6.700 6-10.500z',
  );
  static const key = UstaIconData(
    'M8 11a4 4 0 1 0 0 8a4 4 0 0 0 0-8z M11 12.200L20 3.500 M16.500 7l3 3 M14 9.500l2.500 2.500',
  );
  static const camera = UstaIconData(
    'M3 7.500h11.500a1.500 1.500 0 0 1 1.500 1.500v6a1.500 1.500 0 0 1-1.500 1.500H3A1.500 1.500 0 0 1 1.500 15V9A1.500 1.500 0 0 1 3 7.500z M16 11l5-3v8l-5-3',
  );
  static const plasterboard = UstaIconData(
    'M4 4h16v16H4z M8 8v.01 M16 8v.01 M8 16v.01 M16 16v.01',
  );
  static const parquet = UstaIconData(
    'M3 4h18v16H3z M3 9.300h18 M3 14.700h18 M9 4v5.300 M15 9.300v5.400 M8 14.700V20',
  );
  static const tile = UstaIconData('M12 3l9 9-9 9-9-9z M12 3v18 M3 12h18');
  static const boiler = UstaIconData(
    'M6 3h12a1.500 1.500 0 0 1 1.500 1.500v12A1.500 1.500 0 0 1 18 18H6a1.500 1.500 0 0 1-1.500-1.500v-12A1.500 1.500 0 0 1 6 3z M9 21v-3 M15 21v-3 M12 7a3 3 0 1 0 0 6a3 3 0 0 0 0-6z',
  );
  static const airConditioner = UstaIconData(
    'M3 5h18a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z M5 10h14 M7 17c0 1.500 1 1.500 1 3 M12 16c0 1.500 1 1.500 1 3 M17 17c0 1.500 1 1.500 1 3',
  );
  static const radiator = UstaIconData(
    'M3 6h18a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1z M7 9v5 M11 9v5 M15 9v5 M19 9v5 M5 17v3 M19 17v3',
  );
  static const washingMachine = UstaIconData(
    'M5 3h14a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z M4 8h16 M12 11a4.500 4.500 0 1 0 0 9a4.500 4.500 0 0 0 0-9z M7.500 5.500v.01',
  );
  static const tv = UstaIconData(
    'M3 7h18a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z M9 3l3 4 3-4 M8 21h8',
  );
  static const laptop = UstaIconData(
    'M5 5h14a1 1 0 0 1 1 1v9H4V6a1 1 0 0 1 1-1z M2.500 19h19',
  );
  static const bucket = UstaIconData(
    'M4.500 10h15l-1.500 10.500H6z M7 10a5 5 0 0 1 10 0',
  );
  static const sprayCan = UstaIconData(
    'M7 10h8v11H7z M8 10V7h6v3 M11 4v3 M18 6v.01 M19.500 9v.01 M18 12v.01',
  );
  static const sofa = UstaIconData(
    'M4 11V8a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v3 M2 13a2 2 0 0 1 4 0v2h12v-2a2 2 0 0 1 4 0v5H2z M5 18v2 M19 18v2',
  );

  /// A wrench: "usta", and the carpenter's tool glyph.
  static const hammer = UstaIconData(
    'M14.500 9.500l-.4-2.600 2.600-.4L19 4.200A5 5 0 0 0 11.700 10.700L4.600 17.800a2.100 2.100 0 0 0 3 3l7.100-7.100A5 5 0 0 0 20.200 7z',
  );

  // Account, chat and safety
  static const bell = UstaIconData(
    'M12 3.500a6 6 0 0 0-6 6V14l-1.500 3h15L18 14V9.500a6 6 0 0 0-6-6z M10 20.500a2 2 0 0 0 4 0',
  );
  static const settings = UstaIconData(
    'M10.19 5.24 L10.40 2.94 L13.60 2.94 L13.81 5.24 L15.50 5.94 L17.28 4.46 L19.54 6.72 L18.06 8.50 L18.76 10.19 L21.06 10.40 L21.06 13.60 L18.76 13.81 L18.06 15.50 L19.54 17.28 L17.28 19.54 L15.50 18.06 L13.81 18.76 L13.60 21.06 L10.40 21.06 L10.19 18.76 L8.50 18.06 L6.72 19.54 L4.46 17.28 L5.94 15.50 L5.24 13.81 L2.94 13.60 L2.94 10.40 L5.24 10.19 L5.94 8.50 L4.46 6.72 L6.72 4.46 L8.50 5.94z M12 9.2a2.8 2.8 0 1 0 0 5.6a2.8 2.8 0 0 0 0-5.6z',
  );
  static const moon = UstaIconData(
    'M20 14.500A8 8 0 1 1 9.500 4a6.500 6.500 0 0 0 10.500 10.500z',
  );
  static const download = UstaIconData('M12 4v11 M7 11l5 5 5-5 M5 20h14');
  static const logout = UstaIconData(
    'M9 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h3 M16 8l4 4-4 4 M20 12H9',
  );
  static const flag = UstaIconData('M5 21V4 M5 4h11l-2 4 2 4H5');
  static const reply = UstaIconData('M9 7L4 12l5 5 M4 12h10a6 6 0 0 1 6 6v1');
  static const send = UstaIconData('M21 3L10 14 M21 3l-7 18-4-8-8-4z');
  static const copy = UstaIconData(
    'M9 9h10a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V10a1 1 0 0 1 1-1z M5 15V5a1 1 0 0 1 1-1h10',
  );
  static const info = UstaIconData(
    'M12 3a9 9 0 1 0 0 18a9 9 0 0 0 0-18z M12 11v6 M12 7.500v.01',
  );
  static const lock = UstaIconData(
    'M6 11h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-8a1 1 0 0 1 1-1z M8 11V8a4 4 0 0 1 8 0v3',
  );
  static const more = UstaIconData('M5 12v.01 M12 12v.01 M19 12v.01');
  static const crown = UstaIconData(
    'M4 18h16 M4.500 16L3 7l5 4 4-6 4 6 5-4-1.500 9z',
  );
  static const photoCamera = UstaIconData(
    'M4 8h3l1.500-2.500h7L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z M12 10.500a3.500 3.500 0 1 0 0 7a3.500 3.500 0 0 0 0-7z',
  );
}
