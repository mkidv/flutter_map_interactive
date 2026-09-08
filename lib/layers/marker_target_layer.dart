import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/widgets/containers.dart';

class MarkerTargetLayer extends StatelessWidget {
  const MarkerTargetLayer({
    super.key,
    required this.markers,
  });
  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    return Stack(
      children: (List<Marker> markers) sync* {
        for (final marker in markers) {
          if (!marker.inMapBounds(cam)) continue;

          yield FlutterMapContainer(
            camera: cam,
            point: marker.point,
            child: CrossTarget(
              size: 50,
              strokeWidth: 1.5,
            ),
          );
        }
      }(markers)
          .toList(),
    );
  }
}

class CrossTarget extends StatelessWidget {
  // 0..1 of radius

  const CrossTarget({
    super.key,
    this.size = 120,
    this.color = const Color(0xAAAA00FF),
    this.strokeWidth = 2,
    this.innerRing = 0.35,
    this.outerRing = 0.70,
    this.centerGap = 0.0,
  }) : assert(innerRing > 0 && outerRing > innerRing && outerRing <= 1);
  final double size;
  final Color color;
  final double strokeWidth;
  final double innerRing; // 0..1 of radius
  final double outerRing; // 0..1 of radius, must be > innerRing
  final double centerGap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrosshairPainter(
          color: color,
          strokeWidth: strokeWidth,
          innerRing: innerRing,
          outerRing: outerRing,
          centerGap: centerGap,
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter({
    required this.color,
    required this.strokeWidth,
    required this.innerRing,
    required this.outerRing,
    required this.centerGap,
  });
  final Color color;
  final double strokeWidth;
  final double innerRing;
  final double outerRing;
  final double centerGap;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius * innerRing, paint);
    canvas.drawCircle(center, radius * outerRing, paint);

    final gap = radius * centerGap;

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy - gap),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter old) =>
      color != old.color ||
      strokeWidth != old.strokeWidth ||
      innerRing != old.innerRing ||
      outerRing != old.outerRing ||
      centerGap != old.centerGap;
}
