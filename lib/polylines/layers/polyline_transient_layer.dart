import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' hide MarkerLayer;
import 'package:flutter_map_interactive/polylines/controllers/polyline_controller.dart';
import 'package:latlong2/latlong.dart';

class PolylineTransientLayer extends StatelessWidget {
  const PolylineTransientLayer({
    super.key,
    required this.controller,
  });
  final PolylineController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.transientState,
      builder: (context, state, _) {
        if (state == null) return const SizedBox.shrink();

        final original = state.item;
        final startPos = state.origin;
        final currentPos = state.current;

        // Calculate delta
        final deltaLat = currentPos.latitude - startPos.latitude;
        final deltaLng = currentPos.longitude - startPos.longitude;

        final newPoints = original.points.map((p) {
          return LatLng(p.latitude + deltaLat, p.longitude + deltaLng);
        }).toList();

        final draggedPolyline = original.copyWith(
          points: newPoints,
        );

        return PolylineLayer(
          polylines: [draggedPolyline],
        );
      },
    );
  }
}
