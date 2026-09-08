import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_image.dart';

void main() {
  group('OverlayController', () {
    late OverlayController controller;

    final o1 = InteractiveOverlayImage.safe(
      key: const ValueKey('o1'),
      image: kTestImage,
      topLeft: const LatLng(10, 0),
      topRight: const LatLng(10, 10),
      bottomRight: const LatLng(0, 10),
      bottomLeft: const LatLng(0, 0),
    );

    setUp(() {
      controller = OverlayController();
      controller.setOverlays([], resetHistory: true);
    });

    test('add adds overlay', () {
      controller.add(o1);
      expect(controller.current, contains(o1));
    });

    test('remove removes overlay', () {
      controller.add(o1);
      controller.remove(o1.key!);
      expect(controller.current, isEmpty);
    });

    test('move updates entire overlay', () {
      controller.add(o1);

      // Move center to (20, 20). Current center is (5, 5).
      // Delta = (+15, +15).

      controller.move(o1.key!, const LatLng(20, 20));

      final moved = controller.findByKey(o1.key!)!;
      expect(moved.center.latitude, 20.0);
      expect(moved.center.longitude, 20.0);
    });

    test('moveCorner updates specific corner', () {
      controller.add(o1);

      // Move TL from 10,0 to 12,2
      controller.moveCorner(o1.key!, QuadCorner.topLeft, const LatLng(12, 2));

      final moved = controller.findByKey(o1.key!)!;
      expect(moved.corners.topLeft, const LatLng(12, 2));
      expect(moved.corners.topRight, o1.corners.topRight); // Others unchanged
    });

    test('rotate rotates points', () {
      controller.add(o1);
      // Rotate 90 deg
      controller.rotate(o1.key!, 3.14159 / 2); // ~90 deg

      // Assert change happens
      final rotated = controller.findByKey(o1.key!)!;
      expect(rotated.corners.topLeft, isNot(o1.corners.topLeft));
    });

    group('Interactions', () {
      setUp(() {
        controller.add(o1);
      });

      test('selection callbacks', () {
        InteractiveOverlayImage? active;
        controller.setOptions(InteractiveOptions(
          onActive: (o) => active = o as InteractiveOverlayImage?,
        ));

        controller.select(o1);
        expect(active, o1);
        expect(controller.activeItem, o1);
      });

      test('drag flow updates transient state', () {
        controller.startDrag(o1, o1.center);
        expect(controller.transientState.value, isNotNull);

        controller.updateDrag(const LatLng(100, 100)); // Far away
        expect(
            controller.transientState.value!.current, const LatLng(100, 100));
        // Ensure actual item in 'current' list not updated yet
        expect(controller.findByKey(o1.key!)!.center, o1.center);

        controller.endDrag();
        expect(controller.transientState.value, isNull);
        // Now updated
        expect(controller.findByKey(o1.key!)!.center.latitude, 100.0);
      });
    });
  });
}
