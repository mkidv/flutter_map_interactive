import 'dart:ui';

import 'package:flutter_map_interactive/utils/rect_ops.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RectOps', () {
    test('xor returns both if no overlap', () {
      final r1 = const Rect.fromLTWH(0, 0, 10, 10);
      final r2 = const Rect.fromLTWH(20, 20, 10, 10);
      final result = r1.xor(r2);
      expect(result, hasLength(2));
      expect(result, containsAll([r1, r2]));
    });

    test('xor subtracts overlap', () {
      // 0..20 square
      final r1 = const Rect.fromLTWH(0, 0, 20, 20);
      // 10..30 square, overlaps right half of r1
      final r2 = const Rect.fromLTWH(10, 0, 20, 20);

      final result = r1.xor(r2);
      // Expected:
      // r1 part: 0..10
      // r2 part: 20..30
      // Overlap 10..20 is removed from both (conceptually) or handled by logic

      // Let's verify via area if shapes are complex, but here we expect distinct rects
      final totalArea =
          result.fold(0.0, (sum, r) => sum + (r.width * r.height));
      // r1 area=400, r2 area=400. Overlap=10*20=200.
      // XOR area should be (400-200) + (400-200) = 400.
      expect(totalArea, 400.0);
    });

    test('minus removes overlap', () {
      final r1 = const Rect.fromLTWH(0, 0, 20, 20);
      final tool = const Rect.fromLTWH(10, 0, 20, 20); // overlaps right half

      final result = r1.minus(tool);
      // Should remain left half: 0..10 x 0..20
      expect(result, hasLength(1));
      expect(result.first, const Rect.fromLTWH(0, 0, 10, 20));
    });

    test('intersectionArea returns correct value', () {
      final r1 = const Rect.fromLTWH(0, 0, 20, 20);
      final r2 = const Rect.fromLTWH(10, 0, 20, 20);
      expect(r1.intersectionArea(r2), 200.0); // 10 width * 20 height
    });

    group('getPanCorrection', () {
      final safeArea = const Rect.fromLTWH(0, 0, 100, 100);

      test('returns zero if inside', () {
        final rect = const Rect.fromLTWH(10, 10, 10, 10);
        expect(getPanCorrection(rect, safeArea), Offset.zero);
      });

      test('corrects left/top overflow', () {
        final rect = const Rect.fromLTWH(-10, -10, 10, 10);
        final correction = getPanCorrection(rect, safeArea);
        expect(correction, const Offset(10, 10)); // Move back to 0,0
      });

      test('corrects right/bottom overflow', () {
        final rect = const Rect.fromLTWH(100, 100, 10, 10);
        // Right edge at 110, safeArea right at 100. Diff = -10
        // But logic: if (right > safeArea.right) ox = safeArea.right - rect.right = 100 - 110 = -10
        final correction = getPanCorrection(rect, safeArea);
        expect(correction, const Offset(-10, -10));
      });
    });

    test('getBounds calculates correct bounding box', () {
      final points = [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(0, 20),
        const Offset(5, 5),
      ];
      final bounds = getBounds(points);
      expect(bounds, const Rect.fromLTRB(0, 0, 10, 20));
    });
  });
}
