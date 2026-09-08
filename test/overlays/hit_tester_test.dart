import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_map_interactive/overlays/utils/hit_tester.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('OverlayHitTester', () {
    late MapCamera cam;

    setUp(() {
      // Setup a basic camera at (0,0) with zoom 10
      cam = MapCamera(
        crs: const Epsg3857(),
        center: const LatLng(0, 0),
        zoom: 10,
        rotation: 0,
        nonRotatedSize: const Size(1000, 1000),
      );
    });

    test('hit detects overlay when point is inside', () {
      final overlay = InteractiveOverlayImage.safe(
        key: const Key('o1'),
        image: const NetworkImage(''),
        topLeft: const LatLng(0.01, -0.01),
        topRight: const LatLng(0.01, 0.01),
        bottomRight: const LatLng(-0.01, 0.01),
        bottomLeft: const LatLng(-0.01, -0.01),
      );

      final tester = OverlayHitTester(cam);
      // Center of screen should be (0,0) latlng, which is inside.
      // Screen center is 500,500
      final centerScreen = Offset(500, 500);

      final result = tester.hit([overlay], centerScreen);
      expect(result, isNotNull);
      expect(result!.key, const Key('o1'));
    });

    test('hit returns null when point is outside bounds', () {
      final overlay = InteractiveOverlayImage.safe(
        key: const Key('o1'),
        image: const NetworkImage(''),
        topLeft: const LatLng(0.01, -0.01),
        topRight: const LatLng(0.01, 0.01),
        bottomRight: const LatLng(-0.01, 0.01),
        bottomLeft: const LatLng(-0.01, -0.01),
      );

      final tester = OverlayHitTester(cam);
      // Point far away.
      final pointScreen =
          Offset(0, 0); // Top-left of screen, should be far from center (0,0)

      final result = tester.hit([overlay], pointScreen);
      expect(result, isNull);
    });

    test('hit returns top-most overlay', () {
      // o1 is bigger and below o2
      final o1 = InteractiveOverlayImage.safe(
        key: const Key('o1'),
        image: const NetworkImage(''),
        topLeft: const LatLng(0.02, -0.02),
        topRight: const LatLng(0.02, 0.02),
        bottomRight: const LatLng(-0.02, 0.02),
        bottomLeft: const LatLng(-0.02, -0.02),
      );

      final o2 = InteractiveOverlayImage.safe(
        key: const Key('o2'),
        image: const NetworkImage(''),
        topLeft: const LatLng(0.01, -0.01),
        topRight: const LatLng(0.01, 0.01),
        bottomRight: const LatLng(-0.01, 0.01),
        bottomLeft: const LatLng(-0.01, -0.01),
      );

      final tester = OverlayHitTester(cam);
      final centerScreen = Offset(500, 500);

      // List order usually implies logical order, but hit tester iterates backward (top is last in list)
      // Wait, let's check hit_tester impl:
      // for (int i = overlays.length - 1; i >= 0; i--)
      // So last element is checked first (top-most).

      final result = tester.hit([o1, o2], centerScreen);
      expect(result, isNotNull);
      expect(result!.key, const Key('o2'));
    });
  });
}
