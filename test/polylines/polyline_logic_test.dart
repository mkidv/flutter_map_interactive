import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/polylines/controllers/op.dart';
import 'package:flutter_map_interactive/polylines/logic/polyline_logic.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PolylineLogic', () {
    late PolylineLogic logic;
    late InteractiveOptions<InteractivePolyline> options;

    setUp(() {
      options = const InteractiveOptions<InteractivePolyline>();
      logic = PolylineLogic(() => options);
    });

    group('Key Management', () {
      test('getItemKey returns polyline key', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        expect(logic.getItemKey(polyline), const ValueKey('p1'));
      });

      test('ensureHasKey throws when key is missing', () {
        final polyline = InteractivePolyline(
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        expect(
          () => logic.ensureHasKey(polyline),
          throwsArgumentError,
        );
      });

      test('ensureHasKey does not throw when key exists', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        expect(
          () => logic.ensureHasKey(polyline),
          returnsNormally,
        );
      });
    });

    group('Spatial Change Detection', () {
      test('hasSpatialChange detects points added', () {
        final oldPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );
        final newPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [
            const LatLng(0, 0),
            const LatLng(10, 10),
            const LatLng(20, 20)
          ],
        );

        expect(logic.hasSpatialChange(oldPolyline, newPolyline), isTrue);
      });

      test('hasSpatialChange detects points removed', () {
        final oldPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [
            const LatLng(0, 0),
            const LatLng(10, 10),
            const LatLng(20, 20)
          ],
        );
        final newPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        expect(logic.hasSpatialChange(oldPolyline, newPolyline), isTrue);
      });

      test('hasSpatialChange detects point position changes', () {
        final oldPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );
        final newPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(15, 15)],
        );

        expect(logic.hasSpatialChange(oldPolyline, newPolyline), isTrue);
      });

      test('hasSpatialChange returns false when points identical', () {
        final oldPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );
        final newPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        expect(logic.hasSpatialChange(oldPolyline, newPolyline), isFalse);
      });

      test('hasSpatialChange ignores non-spatial changes', () {
        final oldPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
          strokeWidth: 2.0,
        );
        final newPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
          strokeWidth: 5.0,
        );

        expect(logic.hasSpatialChange(oldPolyline, newPolyline), isFalse);
      });
    });

    group('Operation Creation', () {
      test('createAddOp creates PolylineOp.add', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        final op = logic.createAddOp(polyline);

        expect(op, isA<PolylineOp>());
        final items = <InteractivePolyline>[];
        op.apply(items);
        expect(items, contains(polyline));
      });

      test('createRemoveOp creates PolylineOp.remove', () {
        const key = ValueKey('p1');
        final op = logic.createRemoveOp(key);

        expect(op, isA<PolylineOp>());
      });

      test('createUpdateOp creates PolylineOp.update', () {
        final oldPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );
        final newPolyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(20, 20)],
        );

        final op = logic.createUpdateOp(oldPolyline, newPolyline);

        expect(op, isA<PolylineOp>());
      });

      test('createDragEndOp translates all points correctly', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [
            const LatLng(0, 0),
            const LatLng(10, 10),
            const LatLng(20, 20)
          ],
        );
        const origin = LatLng(5, 5);
        const current = LatLng(10, 10);

        final op = logic.createDragEndOp(polyline, origin, current);

        expect(op, isNotNull);
        expect(op, isA<PolylineOp>());

        // Verify the operation translates all points
        final items = [polyline];
        op!.apply(items);

        final moved = items.first;
        expect(moved.points.length, 3);
        // Delta: lat +5, lng +5
        expect(moved.points[0], const LatLng(5, 5));
        expect(moved.points[1], const LatLng(15, 15));
        expect(moved.points[2], const LatLng(25, 25));
      });

      test('createDragEndOp preserves other properties', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
          strokeWidth: 5.0,
          color: const Color(0xFF0000FF),
        );
        const origin = LatLng(0, 0);
        const current = LatLng(5, 5);

        final op = logic.createDragEndOp(polyline, origin, current);

        final items = [polyline];
        op!.apply(items);

        final moved = items.first;
        expect(moved.strokeWidth, 5.0);
        expect(moved.color, const Color(0xFF0000FF));
      });

      test('createDragEndOp returns null when polyline has no key', () {
        final polyline = InteractivePolyline(
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );
        const origin = LatLng(0, 0);
        const current = LatLng(5, 5);

        final op = logic.createDragEndOp(polyline, origin, current);

        expect(op, isNull);
      });

      test('createDragEndOp handles zero delta', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(5, 5), const LatLng(10, 10)],
        );
        const origin = LatLng(0, 0);
        const current = LatLng(0, 0);

        final op = logic.createDragEndOp(polyline, origin, current);

        final items = [polyline];
        op!.apply(items);

        final moved = items.first;
        expect(moved.points[0], const LatLng(5, 5));
        expect(moved.points[1], const LatLng(10, 10));
      });
    });

    group('Interaction Callbacks', () {
      test('onInteraction does not throw', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        expect(
          () => logic.onInteraction(polyline, InteractionType.tap),
          returnsNormally,
        );
        expect(
          () => logic.onInteraction(polyline, InteractionType.hover),
          returnsNormally,
        );
        expect(
          () => logic.onInteraction(polyline, InteractionType.longPress),
          returnsNormally,
        );
        expect(
          () => logic.onInteraction(polyline, InteractionType.active),
          returnsNormally,
        );
      });
    });

    group('Drag Updates', () {
      test('onDragUpdate does not throw', () {
        final polyline = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)],
        );

        expect(
          () => logic.onDragUpdate(
              polyline, const LatLng(0, 0), const LatLng(5, 5)),
          returnsNormally,
        );
      });
    });
  });
}
