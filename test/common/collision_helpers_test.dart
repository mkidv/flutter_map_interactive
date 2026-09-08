import 'package:flutter/painting.dart';
import 'package:flutter_map_interactive/common/collision/strategies/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Collision scoring', () {
    test('prefers candidate closer to previous offset', () {
      final slots = [const Rect.fromLTWH(0, 0, 60, 60)];

      final near = placementScore(
        candidate: const Offset(12, 0),
        previous: const Offset(10, 0),
        outward: const Offset(1, 0),
        candidateRect: const Rect.fromLTWH(10, 10, 20, 10),
        slots: slots,
      );

      final far = placementScore(
        candidate: const Offset(48, 0),
        previous: const Offset(10, 0),
        outward: const Offset(1, 0),
        candidateRect: const Rect.fromLTWH(2, 10, 20, 10),
        slots: slots,
      );

      expect(near, lessThan(far));
    });

    test('prefers candidate with better slot clearance', () {
      final slots = [const Rect.fromLTWH(0, 0, 60, 60)];

      final centered = placementScore(
        candidate: const Offset(24, 0),
        previous: const Offset(24, 0),
        outward: const Offset(1, 0),
        candidateRect: const Rect.fromLTWH(20, 20, 20, 10),
        slots: slots,
      );

      final edgePinned = placementScore(
        candidate: const Offset(24, 0),
        previous: const Offset(24, 0),
        outward: const Offset(1, 0),
        candidateRect: const Rect.fromLTWH(0, 20, 20, 10),
        slots: slots,
      );

      expect(centered, lessThan(edgePinned));
    });

    test('prefers candidate closer to slot center when both fit', () {
      final slots = [const Rect.fromLTWH(0, 0, 80, 80)];

      final centered = placementScore(
        candidate: const Offset(20, 20),
        previous: const Offset(20, 20),
        outward: const Offset(1, 0),
        candidateRect: const Rect.fromLTWH(25, 25, 20, 20),
        slots: slots,
      );

      final cornerPinned = placementScore(
        candidate: const Offset(20, 20),
        previous: const Offset(20, 20),
        outward: const Offset(1, 0),
        candidateRect: const Rect.fromLTWH(0, 0, 20, 20),
        slots: slots,
      );

      expect(centered, lessThan(cornerPinned));
    });

    test('penalizes connectors crossing already placed labels', () {
      final slots = [const Rect.fromLTWH(0, 0, 120, 120)];
      final obstacle = const Rect.fromLTWH(45, 45, 20, 20);

      final clear = placementScore(
        candidate: const Offset(40, -20),
        previous: const Offset(0, 0),
        outward: const Offset(1, 0),
        connectorStart: const Offset(10, 10),
        connectorEnd: const Offset(40, 10),
        candidateRect: const Rect.fromLTWH(30, 0, 20, 20),
        slots: slots,
        obstacles: [obstacle],
      );

      final crossing = placementScore(
        candidate: const Offset(50, 50),
        previous: const Offset(0, 0),
        outward: const Offset(1, 0),
        connectorStart: const Offset(10, 10),
        connectorEnd: const Offset(70, 70),
        candidateRect: const Rect.fromLTWH(60, 60, 20, 20),
        slots: slots,
        obstacles: [obstacle],
      );

      expect(clear, lessThan(crossing));
    });

    test('provides alternate alignment offsets around the default anchor', () {
      final offsets = candidateAlignmentOffsets(
        anchorPx: const Offset(100, 100),
        size: const Size(20, 10),
        currentAlignment: Alignment.topCenter,
        margin: EdgeInsets.zero,
        rotate: false,
        mapRotationRad: 0,
      );

      expect(offsets, isNotEmpty);
      expect(offsets.first, Offset.zero);
      expect(offsets.any((offset) => offset != Offset.zero), isTrue);
    });
  });
}
