import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/polylines/controllers/polyline_controller.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PolylineController', () {
    late PolylineController controller;
    final p1 = InteractivePolyline.safe(
      key: const ValueKey('p1'),
      points: [const LatLng(0, 0), const LatLng(10, 10)],
    );

    setUp(() {
      controller = PolylineController();
      controller.setPolylines([], resetHistory: true);
    });

    test('add adds polyline', () {
      controller.add(p1);
      expect(controller.current, contains(p1));
    });

    test('remove removes polyline', () {
      controller.add(p1);
      controller.remove(p1.key!);
      expect(controller.current, isEmpty);
    });

    test('update points directly', () {
      controller.add(p1);
      final newPoints = [const LatLng(5, 5), const LatLng(15, 15)];

      controller.updatePoints(p1.key!, newPoints);

      final updated = controller.findByKey(p1.key!)!;
      expect(updated.points, newPoints);
      expect(updated.points, isNot(p1.points));
    });

    test('movePoint modifies single point', () {
      controller.add(p1); // (0,0), (10,10)

      // Move index 0 to (1,1)
      controller.movePoint(
        key: p1.key!,
        index: 0,
        from: const LatLng(0, 0),
        to: const LatLng(1, 1),
      );

      final updated = controller.findByKey(p1.key!)!;
      expect(updated.points[0], const LatLng(1, 1));
      expect(updated.points[1], const LatLng(10, 10));
    });

    test('move translates entire polyline', () {
      // Bounds: 0,0 to 10,10. Center: 5,5.
      controller.add(p1);

      // Move center to 10,10. Delta: +5, +5.
      controller.move(p1.key!, const LatLng(10, 10));

      final updated = controller.findByKey(p1.key!)!;

      // 0,0 -> 5,5 (-ish due to geodetic center calculation)
      // 10,10 -> 15,15 (-ish)
      expect(updated.points[0].latitude, closeTo(5.0, 0.05));
      expect(updated.points[0].longitude, closeTo(5.0, 0.05));
      expect(updated.points[1].latitude, closeTo(15.0, 0.05));
      expect(updated.points[1].longitude, closeTo(15.0, 0.05));
    });

    group('Interactions', () {
      setUp(() {
        controller.add(p1);
      });

      test('selection works', () {
        InteractivePolyline? active;
        controller.setOptions(InteractiveOptions(
          onActive: (p) => active = p,
        ));

        controller.select(p1);
        expect(active, p1);
        expect(controller.activeItem, p1);
      });

      test('drag flow updates transient state', () {
        // Start drag at index 0 (logic depends on how drag is initiated usually via handle)
        // But controller.startDrag just needs key and arbitrary start pos for standard drag?
        // Actually Polyline drag is usually whole-object drag or handle drag?
        // Controller.startDrag sets transient state for whole object translation usually?
        // Let's check implementation behavior:
        // It hides the object and sets transient state.
        // It expects updateDrag/endDrag to move the whole object.

        controller.startDrag(p1, const LatLng(0, 0));
        expect(controller.transientState.value, isNotNull);
        expect(controller.transientKeys, contains(p1.key));

        controller.updateDrag(const LatLng(5, 5));
        expect(controller.transientState.value!.current, const LatLng(5, 5));
        // Real object not moved yet
        expect(controller.findByKey(p1.key!)!.points[0], const LatLng(0, 0));

        controller.endDrag();
        // Should be moved by +5,+5
        final updated = controller.findByKey(p1.key!)!;
        expect(updated.points[0], const LatLng(5, 5));
        expect(controller.transientKeys, isEmpty);
      });
    });
  });
}
