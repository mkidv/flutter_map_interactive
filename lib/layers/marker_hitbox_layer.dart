import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';

class MarkerHitboxLayer extends StatelessWidget {
  const MarkerHitboxLayer({
    super.key,
    required this.markers,
    required this.options,
  });
  final List<Marker> markers;
  final MarkerLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = MarkerController.of(context);

    return IgnorePointer(
      child: CustomPaint(
        painter: _MarkerHitboxPainter(
            cam: cam,
            markers: markers,
            options: options,
            isActiveKey: controller.isActiveKey),
      ),
    );
  }
}

class _MarkerHitboxPainter extends CustomPainter {
  _MarkerHitboxPainter({
    required this.cam,
    required this.markers,
    required this.options,
    required this.isActiveKey,
  });
  final MapCamera cam;
  final List<Marker> markers;
  final MarkerLayerOptions options;
  final bool Function(Key?) isActiveKey;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final m in markers) {
      final isActive = isActiveKey.call(m.key);

      paint.color = isActive
          ? const Color(0x660000FF) // Blue-ish for active
          : const Color(0x44FF0000); // Red-ish for others

      final rect = m.pixelBounds(cam, options: options, active: isActive);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_MarkerHitboxPainter oldDelegate) =>
      !identical(oldDelegate.markers, markers);
}
