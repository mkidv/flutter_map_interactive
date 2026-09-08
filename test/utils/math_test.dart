import 'package:flutter_map_interactive/utils/math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Math Utils', () {
    group('signedArea', () {
      test('calculates correct area for a square', () {
        final square = [
          const Offset(0, 0),
          const Offset(10, 0),
          const Offset(10, 10),
          const Offset(0, 10),
        ];
        // Counter-clockwise
        expect(signedArea(square), 100.0);

        // Clockwise
        expect(signedArea(square.reversed.toList()), -100.0);
      });

      test('calculates correct area for a triangle', () {
        final tri = [
          const Offset(0, 0),
          const Offset(10, 0),
          const Offset(0, 10),
        ];
        expect(signedArea(tri), 50.0);
      });
    });

    group('pointInTri', () {
      final a = const Offset(0, 0);
      final b = const Offset(10, 0);
      final c = const Offset(0, 10);

      test('returns true for point inside', () {
        expect(pointInTri(const Offset(2, 2), a, b, c), isTrue);
      });

      test('returns false for point outside', () {
        expect(pointInTri(const Offset(10, 10), a, b, c), isFalse);
      });

      test('returns true for point on edge', () {
        expect(pointInTri(const Offset(5, 0), a, b, c), isTrue);
      });
    });

    group('pointInQuad', () {
      final quad = [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(10, 10),
        const Offset(0, 10),
      ];

      test('returns true for point inside', () {
        expect(pointInQuad(const Offset(5, 5), quad), isTrue);
      });

      test('returns false for point outside', () {
        expect(pointInQuad(const Offset(15, 5), quad), isFalse);
      });
    });

    group('distToSegment', () {
      final v = const Offset(0, 0);
      final w = const Offset(10, 0);

      test('calculates distance to line segment correctly', () {
        // Point above the line
        expect(distToSegment(const Offset(5, 5), v, w), 5.0);
        // Point on the line
        expect(distToSegment(const Offset(5, 0), v, w), 0.0);
        // Point beyond end w
        expect(distToSegment(const Offset(12, 0), v, w), 2.0);
        // Point before start v
        expect(distToSegment(const Offset(-2, 0), v, w), 2.0);
      });
    });

    group('snap', () {
      test('snaps to nearest step', () {
        expect(snap(12, 10), 10.0);
        expect(snap(16, 10), 20.0);
        expect(snap(5, 0), 5.0);
      });
    });

    group('metersPerPixel', () {
      test('calculates reasonably at equator', () {
        // Earth circ ~40k km. At zoom 1 (512px width for world?),
        // 40075016 / (256 * 2^1) = 40075016 / 512 = 78271.5
        expect(metersPerPixel(0, 1), closeTo(78271.5, 1.0));
      });
    });

    group('centroid', () {
      test('calculates correct average center', () {
        final points = [
          const LatLng(0, 0),
          const LatLng(10, 10),
        ];
        final center = centroid(points);
        expect(center.latitude, 5.0);
        expect(center.longitude, 5.0);
      });

      test('returns 0,0 for empty list', () {
        expect(centroid([]), const LatLng(0, 0));
      });
    });
  });
}
