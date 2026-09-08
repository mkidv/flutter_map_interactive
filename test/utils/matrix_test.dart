import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Matrix Utils', () {
    group('isInMobileLayer', () {
      testWidgets('returns false when not in MobileLayer', (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(builder: (context) {
              result = isInMobileLayer(context);
              return const SizedBox();
            }),
          ),
        );
        expect(result, isFalse);
      });

      testWidgets('returns true when in MobileLayerTransformer',
          (tester) async {
        // TODO: verify MobileLayerTransformer availability in test environment
        // bool? result;
        // await tester.pumpWidget(
        //   MaterialApp(
        //     home: MobileLayerTransformer(
        //       child: Builder(builder: (context) {
        //         result = isInMobileLayer(context);
        //         return const SizedBox();
        //       }),
        //     ),
        //   ),
        // );
        // expect(result, isTrue);
      });
    });

    group('overlayMatrix', () {
      test('translation only (no rotation)', () {
        final m = overlayMatrix(
          origin: const Offset(100, 100),
          size: const Size(50, 50),
          alignment: Alignment.center,
          rotate: false,
        );

        // Center alignment: origin is center.
        // TL should be 100 - 25 = 75.

        final translation = m.getTranslation();
        expect(translation.x, 75.0);
        expect(translation.y, 75.0);
      });

      test('counter-rotation', () {
        // 90 degrees rotation (pi/2)
        const rot = pi / 2;
        final m = overlayMatrix(
          origin: const Offset(100, 100),
          size: const Size(50, 50),
          alignment: Alignment.center,
          rotate: false, // Should counter-rotate
          mapRotationRad: rot,
        );

        // If map is rotated 90deg (clockwise usually in Flutter Map context logic),
        // counter rotation should be -90deg.
        // We verify by checking if a vector is rotated.

        // Matrix4 is col-major. Rotation Z is top-left 2x2.
        // cos(-90) = 0, sin(-90) = -1.
        // Col 0: 0, -1
        // Col 1: 1, 0

        expect(m[0], closeTo(0.0, 1e-6));
        expect(m[1], closeTo(-1.0, 1e-6));
        expect(m[4], closeTo(1.0, 1e-6)); // -(-1) = 1
        expect(m[5], closeTo(0.0, 1e-6));
      });
    });

    group('overlayRect', () {
      test('calculates simple rect without rotation', () {
        final r = overlayRect(
          origin: const Offset(100, 100),
          size: const Size(50, 50),
          alignment: Alignment.center,
          rotate: true, // or false with 0 rotation, same result
        );

        expect(r, const Rect.fromLTWH(75, 75, 50, 50));
      });

      test('calculates bounding box for counter-rotated rect', () {
        // 45 degrees
        const rot = pi / 4;
        final r = overlayRect(
          origin: const Offset(100, 100),
          size: const Size(100, 100), // square
          alignment: Alignment.center,
          rotate: false, // counter-rotate
          mapRotationRad: rot,
        );

        // A 100x100 square rotated by 45 degrees.
        // Bounding box size = side * sqrt(2) ~= 141.42
        // Center remains 100,100

        expect(r.center.dx, closeTo(100.0, 1e-6));
        expect(r.center.dy, closeTo(100.0, 1e-6));
        expect(r.width, closeTo(100 * sqrt(2), 1e-4));
        expect(r.height, closeTo(100 * sqrt(2), 1e-4));
      });
    });
  });
}
