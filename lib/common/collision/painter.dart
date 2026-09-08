import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';

enum ConnectorStyle { straight, curved }

class ConnectorPainter extends CustomPainter {
  ConnectorPainter({
    required this.cam,
    required this.nodes,
    required this.placements,
    required this.color,
    required this.strokeWidth,
    required this.defaultSize,
    this.style = ConnectorStyle.curved,
    this.bendFactor = 17.0,
    this.minLengthPx = 3.0,
    this.startGapPx = 0.5,
    this.endGapPx = 4.0,
    this.halo = true,
    this.haloWidth = 1.35,
    this.haloColor = const Color(0xFFFFFFFF),
    this.haloAlpha = 76,
    this.startAlpha = 112,
    this.endAlpha = 188,
    this.dashed = false,
    this.dash = 6.0,
    this.gap = 4.0,
    this.endDot = false,
    this.endDotRadius = 2.5,
    this.startDot = false,
    this.startDotRadius = 2.5,
    super.repaint,
  });

  final MapCamera cam;
  final List<CollisionNode<Object?>> nodes;
  final List<CollisionPlacement> placements;

  final Color color;
  final double strokeWidth;

  final ConnectorStyle style;
  final double bendFactor;
  final Size defaultSize;
  final double minLengthPx;
  final double startGapPx;
  final double endGapPx;

  final bool halo;
  final double haloWidth;
  final Color haloColor;
  final int haloAlpha;

  final int startAlpha;
  final int endAlpha;

  final bool dashed;
  final double dash;
  final double gap;

  final bool startDot;
  final double startDotRadius;
  final bool endDot;
  final double endDotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final placementsByKey = {
      for (final placement in placements) placement.key: placement,
    };

    for (final node in nodes) {
      final placement = placementsByKey[node.key];
      if (placement == null) continue;

      if (!node.drawConnector || !placement.showConnector) continue;

      final offset = placement.offsetPx;
      if (offset.distance < minLengthPx) continue;

      final anchorPx = cam.latLngToScreenOffset(node.anchor);
      final labelRect = overlayRect(
        origin: anchorPx,
        size: node.knownSize ?? defaultSize,
        alignment: node.alignment * -1,
        mapRotationRad: cam.rotationRad,
        rotate: node.rotate,
        margin: node.margin ?? EdgeInsets.zero,
        pixelOffset: offset,
      );

      final start = anchorPx;

      final end =
          _edgeAlongRay(labelRect, labelRect.center, anchorPx, gap: endGapPx);
      if (end == null) continue;

      final distance = (end - start).distance;
      if (distance < minLengthPx) continue;

      final path = _buildPath(start, end);
      final paintedPath = _maybeDash(path, distance);

      _paintBody(canvas, paintedPath);
    }
  }

  Path _buildPath(Offset start, Offset end) {
    final path = Path()..moveTo(start.dx, start.dy);
    if (style == ConnectorStyle.straight) {
      path.lineTo(end.dx, end.dy);
      return path;
    }

    final vector = end - start;
    final distance = vector.distance;
    final tangent = distance > 1e-6 ? vector / distance : const Offset(1, 0);
    final normal = Offset(-tangent.dy, tangent.dx);

    final cp1 =
        start + tangent * (distance * 0.14) + normal * (bendFactor * 0.5);
    final cp2 =
        end - tangent * (distance * 0.16) + normal * (bendFactor * 0.16);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    return path;
  }

  void _paintBody(Canvas canvas, Path path) {
    final bounds = path.getBounds();
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 2.0
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6);
    canvas.drawPath(path, shadow);

    final shaderStart = Offset(bounds.left, bounds.center.dy);
    final shaderEnd = Offset(bounds.right, bounds.center.dy);
    final gradient = LinearGradient(
      colors: [
        const Color(0x00000000),
        const Color(0xDD000000),
        const Color(0x00000000),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final core = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(Rect.fromPoints(shaderStart, shaderEnd));
    canvas.drawPath(path, core);
  }

  Path _maybeDash(Path src, double length) {
    if (!dashed) return src;
    if (length < dash * 3) return src;
    return _dashPath(src, dash, gap);
  }

  Offset? _edgeAlongRay(Rect rect, Offset from, Offset to, {double gap = 0}) {
    final vector = to - from;
    final vx = vector.dx;
    final vy = vector.dy;
    if (vx.abs() < 1e-6 && vy.abs() < 1e-6) return null;

    double? bestT;

    if (vx != 0) {
      for (final x in [rect.left, rect.right]) {
        final t = (x - from.dx) / vx;
        final y = from.dy + t * vy;
        if (t > 0 && y >= rect.top - 1e-6 && y <= rect.bottom + 1e-6) {
          if (bestT == null || t < bestT) bestT = t;
        }
      }
    }

    if (vy != 0) {
      for (final y in [rect.top, rect.bottom]) {
        final t = (y - from.dy) / vy;
        final x = from.dx + t * vx;
        if (t > 0 && x >= rect.left - 1e-6 && x <= rect.right + 1e-6) {
          if (bestT == null || t < bestT) bestT = t;
        }
      }
    }

    if (bestT == null) return null;

    var point = from + vector * bestT;
    if (gap > 0) {
      final distance = vector.distance;
      if (distance > 1e-6) point += vector / distance * gap;
    }
    return point;
  }

  Path _dashPath(Path src, double dash, double gap) {
    final out = Path();
    for (final metric in src.computeMetrics()) {
      var dist = 0.0;
      var draw = true;
      while (dist < metric.length) {
        final segment = draw ? dash : gap;
        final next = math.min(dist + segment, metric.length);
        if (draw) out.addPath(metric.extractPath(dist, next), Offset.zero);
        dist = next;
        draw = !draw;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter old) =>
      !identical(old.nodes, nodes) ||
      !identical(old.placements, placements) ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.defaultSize != defaultSize ||
      old.minLengthPx != minLengthPx ||
      old.startGapPx != startGapPx ||
      old.endGapPx != endGapPx ||
      old.halo != halo ||
      old.haloWidth != haloWidth ||
      old.haloColor != haloColor ||
      old.haloAlpha != haloAlpha ||
      old.startAlpha != startAlpha ||
      old.endAlpha != endAlpha ||
      old.dashed != dashed ||
      old.dash != dash ||
      old.gap != gap ||
      old.endDot != endDot ||
      old.endDotRadius != endDotRadius ||
      old.startDot != startDot ||
      old.startDotRadius != startDotRadius ||
      old.style != style ||
      old.bendFactor != bendFactor ||
      old.cam.center != cam.center ||
      old.cam.rotation != cam.rotation;
}
