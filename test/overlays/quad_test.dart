import 'package:flutter_map_interactive/overlays/models/quad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('QuadLatLng', () {
    const tl = LatLng(10, -10);
    const tr = LatLng(10, 10);
    const br = LatLng(-10, 10);
    const bl = LatLng(-10, -10);
    const quad = QuadLatLng(
      topLeft: tl,
      topRight: tr,
      bottomRight: br,
      bottomLeft: bl,
    );

    test('bounds should encompass all corners', () {
      final bounds = quad.bounds;
      expect(bounds.contains(tl), isTrue);
      expect(bounds.contains(tr), isTrue);
      expect(bounds.contains(br), isTrue);
      expect(bounds.contains(bl), isTrue);
      expect(bounds.north, 10);
      expect(bounds.south, -10);
      expect(bounds.east, 10);
      expect(bounds.west, -10);
    });

    test('center should be correct', () {
      expect(quad.center.latitude, 0);
      expect(quad.center.longitude, 0);
    });

    test('translate should move all corners', () {
      final moved = quad.translate(1, 2);
      expect(moved.topLeft, const LatLng(11, -8));
      expect(moved.topRight, const LatLng(11, 12));
      expect(moved.bottomRight, const LatLng(-9, 12));
      expect(moved.bottomLeft, const LatLng(-9, -8));
    });

    test('rotate should rotate corners', () {
      // Rotate 90 degrees clockwise (which is +PI/2 bearing change, roughly)
      // Note: exact lat/lng rotation depends on projection but here we use geodesic Distance
      // For simple checking, let's just check if it changed reasonably.
      // 90 deg rotation of (10,10) (TR) around (0,0) should go to roughly (-10, 10) (BR)
      // Bearing from 0,0 to 10,10 (NE) is 45 deg. +90 = 135 deg (SE). Distance same.

      // Let's test with PI/2 (90 deg)
      final rotated = quad.rotate(pi / 2);

      // TR (45 deg) -> BR (135 deg)
      expect(rotated.topRight.latitude, closeTo(-10, 0.5));
      expect(rotated.topRight.longitude, closeTo(10, 0.5));

      // TL (-45 deg / 315) -> TR (45)
      expect(rotated.topLeft.latitude, closeTo(10, 0.5));
      expect(rotated.topLeft.longitude, closeTo(10, 0.5));
    });

    test('contains should detect points inside', () {
      expect(quad.contains(const LatLng(0, 0)), isTrue);
      expect(quad.contains(const LatLng(5, 5)), isTrue);
      expect(quad.contains(const LatLng(9, 9)), isTrue);

      // Concave behavior / exact edge cases might vary with projection but for now:
      expect(quad.contains(const LatLng(11, 0)), isFalse);
      expect(quad.contains(const LatLng(0, 11)), isFalse);
    });

    test('contains works for rotated quad', () {
      // Rotate 45 deg. Bounds become diamond shape.
      final rotated = quad.rotate(pi / 4);
      // (0,0) still inside
      expect(rotated.contains(const LatLng(0, 0)), isTrue);

      // Old corner (10, 10) might be outside if rotated?
      // With 45 deg rotation, corners move "out". The box is bigger? No, same size rotated.
      // Actually if we rotate 45 deg, the corners are on axes.
      // TR (45 deg) -> (90 deg) -> (0, Y)
      // So (0, ~14) should be a corner.
      // So (0, 10) should be inside.
      expect(rotated.contains(const LatLng(0, 10)), isTrue);
    });
  });
}
