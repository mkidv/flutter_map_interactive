import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/polylines/interactive_polyline_scope.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';

class PolylineHitboxLayer extends StatelessWidget {
  const PolylineHitboxLayer({
    super.key,
    required this.polylines,
    this.hitTolerance = 24.0,
  });
  final List<InteractivePolyline> polylines;
  final double hitTolerance;

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    final controller = InteractivePolylineScope.maybeControllerOf(context);

    return IgnorePointer(
      child: CustomPaint(
        painter: _PolylineHitboxPainter(
          camera: map,
          polylines: polylines,
          hitTolerance: hitTolerance,
          isActiveKey: controller?.isActiveKey,
        ),
      ),
    );
  }
}

class _PolylineHitboxPainter extends CustomPainter {
  _PolylineHitboxPainter({
    required this.camera,
    required this.polylines,
    required this.hitTolerance,
    this.isActiveKey,
  });

  final MapCamera camera;
  final List<InteractivePolyline> polylines;
  final double hitTolerance;
  final bool Function(Key?)? isActiveKey;

  @override
  void paint(Canvas canvas, Size size) {
    // Normal paint
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final polyline in polylines) {
      if (polyline.points.isEmpty) continue;

      final isActive = isActiveKey?.call(polyline.key) ?? false;

      paint
        ..color = isActive
            ? const Color(0x660000FF) // Blue-ish for active
            : const Color(0x44FF0000) // Red-ish for others
        ..strokeWidth = hitTolerance * 2;

      final offsets = polyline.points.map(camera.latLngToScreenOffset).toList();

      if (offsets.isEmpty) continue;

      final path = Path()..moveTo(offsets[0].dx, offsets[0].dy);
      for (int i = 1; i < offsets.length; i++) {
        path.lineTo(offsets[i].dx, offsets[i].dy);
      }

      canvas.drawPath(path, paint);

      // Draw circles at vertices to show endpoints tolerance
      paint.style = PaintingStyle.fill;
      for (final offset in offsets) {
        canvas.drawCircle(offset, hitTolerance, paint);
      }
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(_PolylineHitboxPainter oldDelegate) {
    return oldDelegate.camera != camera ||
        oldDelegate.polylines != polylines ||
        oldDelegate.hitTolerance != hitTolerance;
  }
}
