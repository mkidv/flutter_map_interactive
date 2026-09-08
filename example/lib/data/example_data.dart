import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:latlong2/latlong.dart';

class ExampleData {
  const ExampleData._();

  static const latLngStart = LatLng(48.111, -1.680);

  // Overlay Bounds
  static const overlay1Tl = LatLng(48.1165, -1.6900);
  static const overlay1Tr = LatLng(48.1165, -1.6700);
  static const overlay1Br = LatLng(48.1065, -1.6700);
  static const overlay1Bl = LatLng(48.1065, -1.6900);

  static const overlay2Tl = LatLng(48.1105, -1.6900);
  static const overlay2Tr = LatLng(48.1105, -1.6700);
  static const overlay2Br = LatLng(48.1005, -1.6700);
  static const overlay2Bl = LatLng(48.1005, -1.6900);

  static List<({String id, LatLng point})> get markerLocations => [
        (id: 'A', point: const LatLng(48.111, -1.680)),
        (id: 'B', point: const LatLng(48.113, -1.683)),
        (id: 'C', point: const LatLng(48.115, -1.676)),
        (id: 'D', point: const LatLng(48.101, -1.680)),
        (id: 'E', point: const LatLng(48.103, -1.683)),
        (id: 'F', point: const LatLng(48.105, -1.676)),
        (id: 'Outside', point: const LatLng(48.105, -1.618)),
      ];

  static List<({String id, LatLng point})> denseMarkerLocations({
    int rows = 12,
    int cols = 12,
    double latStep = 0.00075,
    double lngStep = 0.00105,
  }) {
    const center = latLngStart;
    final items = <({String id, LatLng point})>[];
    final latOrigin = center.latitude - ((rows - 1) * latStep / 2);
    final lngOrigin = center.longitude - ((cols - 1) * lngStep / 2);

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        items.add((
          id: 'D${row}_$col',
          point: LatLng(
            latOrigin + (row * latStep),
            lngOrigin + (col * lngStep),
          ),
        ));
      }
    }

    return items;
  }

  static List<InteractivePolyline> get initialPolylines => [
        InteractivePolyline(
          key: const ValueKey('polyline1'),
          points: [
            const LatLng(48.130, -1.683),
            const LatLng(48.120, -1.676),
            const LatLng(48.125, -1.676),
          ],
          strokeWidth: 4,
          color: Colors.blue,
        ),
      ];
}
