import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import 'usta_icons.dart';

/// Draws a [UstaIconData] synchronously (no asset loading, so it never pops in).
/// Stroke weight scales with [size] so the family keeps one optical weight.
class UstaIcon extends StatelessWidget {
  const UstaIcon(
    this.data, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final UstaIconData data;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  static final _paths = <String, Path>{};

  static Path _parse(String d) =>
      _paths.putIfAbsent(d, () => parseSvgPathData(d));

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final s = size ?? iconTheme.size ?? 24;
    final c = color ?? iconTheme.color ?? const Color(0xFF000000);
    final icon = SizedBox.square(
      dimension: s,
      child: CustomPaint(
        painter: _IconPainter(_parse(data.path), c, data.filled),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: icon);
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.path, this.color, this.filled);

  final Path path;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
    if (filled) {
      // Soften the points of filled glyphs (rating star) with a matching stroke.
      canvas.drawPath(
        path,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.path != path || old.color != color || old.filled != filled;
}
