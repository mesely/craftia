import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_location.dart';
import 'map_surface.dart';

/// Keyless stand-in for a real map: pins are drawn from their coordinates with
/// distance rings around the user. Pan with one finger, pinch to zoom.
class SchematicMapSurfaceBuilder implements MapSurfaceBuilder {
  const SchematicMapSurfaceBuilder();

  @override
  Widget build(BuildContext context, MapSurfaceData data) =>
      SchematicMapSurface(data: data);
}

class SchematicMapSurface extends StatefulWidget {
  const SchematicMapSurface({super.key, required this.data});

  final MapSurfaceData data;

  @override
  State<SchematicMapSurface> createState() => _SchematicMapSurfaceState();
}

class _SchematicMapSurfaceState extends State<SchematicMapSurface> {
  final _controller = TransformationController();
  late _Projection _projection = _Projection.fit(widget.data);

  @override
  void didUpdateWidget(covariant SchematicMapSurface old) {
    super.didUpdateWidget(old);
    if (!_samePins(old.data.pins, widget.data.pins) ||
        old.data.user != widget.data.user) {
      _projection = _Projection.fit(widget.data);
      _controller.value = Matrix4.identity();
    }
  }

  static bool _samePins(List<MapPin> a, List<MapPin> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(Offset local, Size size) {
    final zoom = _controller.value.getMaxScaleOnAxis();
    final hitRadius = 22 / zoom;
    String? hit;
    var best = double.infinity;
    for (final pin in widget.data.pins) {
      final d = (_projection.toScreen(pin.lat, pin.lng, size) - local).distance;
      if (d < hitRadius && d < best) {
        best = d;
        hit = pin.id;
      }
    }
    widget.data.onPinTap(hit);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return ClipRect(
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: 1,
            maxScale: 12,
            boundaryMargin: EdgeInsets.all(math.max(size.width, size.height)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _onTap(d.localPosition, size),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: _MapPainter(
                    data: widget.data,
                    projection: _projection,
                    controller: _controller,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Equirectangular projection fitted to the pins (+ user), x scaled by cos(lat).
class _Projection {
  _Projection({
    required this.centerLat,
    required this.centerLng,
    required this.spanDegrees,
  });

  final double centerLat;
  final double centerLng;

  /// Larger of the lat / lng spans (lng corrected by cos(lat)), in degrees.
  final double spanDegrees;

  double get _cos => math.cos(centerLat * math.pi / 180);

  static _Projection fit(MapSurfaceData data) {
    final lats = <double>[for (final p in data.pins) p.lat, ?data.user?.lat];
    final lngs = <double>[for (final p in data.pins) p.lng, ?data.user?.lng];
    if (lats.isEmpty) {
      return _Projection(centerLat: 39, centerLng: 35, spanDegrees: 1);
    }
    final minLat = lats.reduce(math.min), maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min), maxLng = lngs.reduce(math.max);
    return _Projection(
      centerLat: (minLat + maxLat) / 2,
      centerLng: (minLng + maxLng) / 2,
      spanDegrees: math.max(
        math.max(maxLat - minLat, 0.02),
        math.max(maxLng - minLng, 0.02) *
            math.cos(((minLat + maxLat) / 2) * math.pi / 180),
      ),
    );
  }

  /// Pixels per degree of latitude for this viewport.
  double scaleFor(Size size) {
    const pad = 56.0;
    final usable = math.min(size.width, size.height) - pad * 2;
    return usable / spanDegrees;
  }

  Offset toScreen(double lat, double lng, Size size) {
    final s = scaleFor(size);
    return Offset(
      size.width / 2 + (lng - centerLng) * _cos * s,
      size.height / 2 - (lat - centerLat) * s,
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.data,
    required this.projection,
    required this.controller,
  }) : super(repaint: controller);

  final MapSurfaceData data;
  final _Projection projection;
  final TransformationController controller;

  static const _ringSteps = [
    1.0,
    2.0,
    5.0,
    10.0,
    25.0,
    50.0,
    100.0,
    250.0,
    500.0,
    1000.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = controller.value.getMaxScaleOnAxis();
    final inv = 1 / zoom;

    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    _drawGrid(canvas, size, inv);

    final user = data.user;
    if (user != null && user.isValid) {
      _drawRings(canvas, size, user, zoom, inv);
    }

    final selected = data.pins
        .where((p) => p.id == data.selectedId)
        .firstOrNull;
    for (final pin in data.pins) {
      if (pin.id != data.selectedId) {
        _drawPin(canvas, size, pin, inv, selected: false);
      }
    }
    if (selected != null) {
      _drawPin(canvas, size, selected, inv, selected: true);
    }
    if (user != null && user.isValid) {
      _drawUser(canvas, size, user, inv);
    }
    if (selected != null) {
      _drawLabel(canvas, size, selected, inv);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double inv) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 1 * inv;
    const cells = 8;
    for (var i = 1; i < cells; i++) {
      final x = size.width * i / cells;
      final y = size.height * i / cells;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawRings(
    Canvas canvas,
    Size size,
    UserLocation user,
    double zoom,
    double inv,
  ) {
    final center = projection.toScreen(user.lat, user.lng, size);
    final pxPerKm = projection.scaleFor(size) / 111.32;
    final step = _ringSteps.firstWhere(
      (km) => km * pxPerKm * zoom >= 70,
      orElse: () => _ringSteps.last,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.primary.withValues(alpha: 0.22)
      ..strokeWidth = 1.2 * inv;
    for (var i = 1; i <= 3; i++) {
      final radius = step * i * pxPerKm;
      canvas.drawCircle(center, radius, paint);
      _text(
        canvas,
        '${(step * i).round()} km',
        center + Offset(0, -radius),
        inv,
        AppTypography.caption.copyWith(color: AppColors.primary, fontSize: 10),
        anchorBottom: true,
      );
    }
  }

  void _drawPin(
    Canvas canvas,
    Size size,
    MapPin pin,
    double inv, {
    required bool selected,
  }) {
    final c = projection.toScreen(pin.lat, pin.lng, size);
    final r = (selected ? 11.0 : 7.0) * inv;
    canvas.drawCircle(c, r + 2.5 * inv, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = selected
            ? AppColors.ink
            : (pin.isFeatured ? AppColors.amber : AppColors.primary),
    );
    if (selected) {
      canvas.drawCircle(c, 3.2 * inv, Paint()..color = AppColors.surface);
    }
  }

  void _drawUser(Canvas canvas, Size size, UserLocation user, double inv) {
    final c = projection.toScreen(user.lat, user.lng, size);
    canvas.drawCircle(
      c,
      16 * inv,
      Paint()..color = AppColors.primary.withValues(alpha: 0.16),
    );
    canvas.drawCircle(c, 7 * inv, Paint()..color = AppColors.surface);
    canvas.drawCircle(c, 5 * inv, Paint()..color = const Color(0xFF2F6FDE));
  }

  void _drawLabel(Canvas canvas, Size size, MapPin pin, double inv) {
    final c = projection.toScreen(pin.lat, pin.lng, size);
    _text(
      canvas,
      pin.label,
      c + Offset(0, -18 * inv),
      inv,
      AppTypography.caption.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      anchorBottom: true,
      background: true,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    double inv,
    TextStyle style, {
    bool anchorBottom = false,
    bool background = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 220);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(inv);
    final origin = Offset(
      -painter.width / 2,
      anchorBottom ? -painter.height : 0,
    );
    if (background) {
      final rect = (origin & painter.size).inflate(5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = AppColors.surface.withValues(alpha: 0.95),
      );
    }
    painter.paint(canvas, origin);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.data.selectedId != data.selectedId ||
      old.data.pins != data.pins ||
      old.data.user != data.user ||
      old.projection != projection;
}
