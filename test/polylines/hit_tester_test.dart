import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_map_interactive/polylines/utils/hit_tester.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PolylineHitTester', () {
    late MapCamera cam;

    setUp(() {
      // Setup a basic camera at (0,0) with zoom 10
      // 1000x1000 pixels. Center (500,500) corresponds to (0,0) latlng.
      cam = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(0, 0),
        zoom: 10,
        rotation: 0,
        nonRotatedSize: const Size(1000, 1000),
      );
    });

    test('hit detects polyline', () {
      final polyline = InteractivePolyline.safe(
        key: const Key('p1'),
        points: [
          const LatLng(0, -0.01),
          const LatLng(0, 0.01)
        ], // Horizontal line through center
        color: const Color(0xFFFF0000),
        strokeWidth: 2.0,
      );

      final tester = PolylineHitTester(cam, hitTolerance: 10.0);
      final centerScreen = Offset(500, 500);

      final result = tester.hit([polyline], centerScreen);
      expect(result, isNotNull);
      expect(result!.key, const Key('p1'));
    });

    test('hit selects closest polyline (bestHit)', () {
      // p1 is at y=0 (center), but let's offset the tap slightly
      // p2 is further away

      // Let's define points accurately.
      // At zoom 10, approx meters/pixel?
      // Let's just rely on screen projection logic.
      // (0,0) -> (500,500).

      final p1 = InteractivePolyline.safe(
        key: const Key('p1'),
        points: [const LatLng(0, -0.01), const LatLng(0, 0.01)], // Center line
        color: const Color(0xFFFF0000),
      );

      final p2 = InteractivePolyline.safe(
        key: const Key('p2'),
        points: [
          const LatLng(0.01, -0.01),
          const LatLng(0.01, 0.01)
        ], // Further above (0.01 deg)
      );

      final tester = PolylineHitTester(cam, hitTolerance: 100.0);

      // Tap exactly on p2
      final o2 = cam.latLngToScreenOffset(const LatLng(0.01, 0));

      final result = tester.hit([p1, p2], o2);
      expect(result, isNotNull);
      expect(result!.key, const Key('p2'));
    });

    test('hit returns direct hit immediately (optimization)', () {
      final p1 = InteractivePolyline.safe(
        key: const Key('p1_top'),
        points: [const LatLng(0, -0.01), const LatLng(0, 0.01)],
        color: const Color(0xFFFF0000),
      );

      final p2 = InteractivePolyline.safe(
        key: const Key('p2_bottom'),
        points: [const LatLng(0, -0.01), const LatLng(0, 0.01)],
      );

      final tester = PolylineHitTester(cam);
      // Tap EXACTLY on the line
      final centerScreen = Offset(500, 500);

      // List is [p2, p1]. p1 is top (last).
      // Iteration: p1 checked first. Distance ~0. Should return p1 immediately.

      final result = tester.hit([p2, p1], centerScreen);
      expect(result!.key, const Key('p1_top'));
    });
  });
}
