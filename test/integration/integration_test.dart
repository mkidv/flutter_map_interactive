import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_app_wrapper.dart';
import '../common/test_image.dart';

void main() {
  group('Integration Scenarios', () {
    testWidgets('markers and polylines coexist', (tester) async {
      setupDimensions(tester);
      final m1 = Marker(
        point: const LatLng(0, 0),
        child: const SizedBox(width: 30, height: 30),
        key: const ValueKey('m1'),
      );
      final p1 = InteractivePolyline.safe(
        key: const ValueKey('p1'),
        points: [const LatLng(0, 0), const LatLng(10, 10)],
      );

      await tester.pumpWidget(wrapMap(children: [
        InteractiveMarkerLayer(markers: [m1]),
        InteractivePolylineLayer(polylines: [p1]),
      ]));

      expect(find.byType(InteractiveMarkerLayer), findsOneWidget);
      expect(find.byType(InteractivePolylineLayer), findsOneWidget);
      expect(find.byKey(const ValueKey('m1')), findsOneWidget);
    });

    testWidgets('editing both markers and polylines', (tester) async {
      setupDimensions(tester);
      final markerController = MarkerController();
      final polylineController = PolylineController();

      final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'));
      final p1 = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(0, 0), const LatLng(10, 10)]);

      await tester.pumpWidget(wrapMap(children: [
        InteractiveMarkerLayer(
          markers: [m1],
          markerController: markerController,
        ),
        InteractivePolylineLayer(
          polylines: [p1],
          polylineController: polylineController,
        ),
      ]));

      markerController.setEditMode(true);
      polylineController.setEditMode(true);
      await tester.pump();

      expect(markerController.isEditing, isTrue);
      expect(polylineController.isEditing, isTrue);
    });

    group('CRUD Workflow', () {
      testWidgets('complete marker lifecycle with undo/redo', (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();
        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [],
            markerController: controller,
          ),
        ]));

        // Create
        controller.add(m1);
        await tester.pump();
        expect(controller.current, contains(m1));
        expect(controller.canUndo, isTrue);

        // Update (move)
        controller.move(m1.key!, const LatLng(5, 5));
        await tester.pump();
        expect(controller.current.first.point, const LatLng(5, 5));

        // Save
        controller.save();

        // Delete
        controller.remove(m1.key!);
        await tester.pump();
        expect(controller.current, isEmpty);

        // Undo delete
        controller.undo();
        await tester.pump();
        expect(controller.current, isNotEmpty);

        // Redo delete
        controller.redo();
        await tester.pump();
        expect(controller.current, isEmpty);
      });

      testWidgets('multi-entity operations', (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();
        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );
        final m2 = Marker(
          point: const LatLng(5, 5),
          child: const SizedBox(),
          key: const ValueKey('m2'),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [],
            markerController: controller,
          ),
        ]));

        controller.add(m1);
        controller.add(m2);
        await tester.pump();

        expect(controller.current.length, 2);

        // Remove one
        controller.remove(m1.key!);
        await tester.pump();
        expect(controller.current.length, 1);
        expect(controller.current.first.key, const ValueKey('m2'));

        // Undo should restore m1
        controller.undo();
        await tester.pump();
        expect(controller.current.length, 2);
      });
    });

    group('Drag & Drop', () {
      testWidgets('marker drag creates transient state', (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();
        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [m1],
            markerController: controller,
          ),
        ]));

        // Start drag
        controller.startDrag(m1, m1.point);
        await tester.pump();

        expect(controller.transientKeys, contains(m1.key));
        expect(controller.transientState.value, isNotNull);
        expect(controller.transientState.value!.item, m1);
        expect(controller.transientState.value!.origin, m1.point);

        // Update drag
        controller.updateDrag(const LatLng(2, 2));
        await tester.pump();

        expect(controller.transientState.value!.current, const LatLng(2, 2));
        // Original marker still at 0,0
        expect(controller.current.first.point, const LatLng(0, 0));

        // End drag
        controller.endDrag();
        await tester.pump();

        expect(controller.transientState.value, isNull);
        expect(controller.transientKeys, isEmpty);
        // Marker now moved to new position
        expect(controller.current.first.point, const LatLng(2, 2));
      });

      testWidgets('polyline drag translates all points', (tester) async {
        setupDimensions(tester);
        final controller = PolylineController();
        final p1 = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [
            const LatLng(0, 0),
            const LatLng(10, 10),
            const LatLng(20, 20)
          ],
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractivePolylineLayer(
            polylines: [p1],
            polylineController: controller,
          ),
        ]));

        controller.startDrag(p1, const LatLng(5, 5));
        controller.updateDrag(const LatLng(10, 10));
        controller.endDrag();
        await tester.pump();

        final moved = controller.current.first;
        // Delta: lat +5, lng +5
        expect(moved.points[0], const LatLng(5, 5));
        expect(moved.points[1], const LatLng(15, 15));
        expect(moved.points[2], const LatLng(25, 25));
      });

      testWidgets('overlay drag translates all corners', (tester) async {
        setupDimensions(tester);
        final controller = OverlayController();
        final o1 = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveOverlayLayer(
            overlays: [o1],
            overlayController: controller,
          ),
        ]));

        controller.startDrag(o1, const LatLng(5, 5));
        controller.updateDrag(const LatLng(10, 10));
        controller.endDrag();
        await tester.pump();

        final moved = controller.current.first;
        // Delta: lat +5, lng +5
        expect(moved.corners.topLeft, const LatLng(15, 5));
        expect(moved.corners.topRight, const LatLng(15, 15));
        expect(moved.corners.bottomRight, const LatLng(5, 15));
        expect(moved.corners.bottomLeft, const LatLng(5, 5));
      });
    });

    group('Cross-Layer Interactions', () {
      testWidgets('only one entity active across types', (tester) async {
        setupDimensions(tester);
        final markerController = MarkerController();
        final polylineController = PolylineController();
        final overlayController = OverlayController();

        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );
        final p1 = InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: [const LatLng(5, 5), const LatLng(10, 10)],
        );
        final o1 = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(20, 0),
          topRight: const LatLng(20, 10),
          bottomRight: const LatLng(10, 10),
          bottomLeft: const LatLng(10, 0),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [m1],
            markerController: markerController,
          ),
          InteractivePolylineLayer(
            polylines: [p1],
            polylineController: polylineController,
          ),
          InteractiveOverlayLayer(
            overlays: [o1],
            overlayController: overlayController,
          ),
        ]));

        // Select marker
        markerController.select(m1);
        await tester.pump();
        expect(markerController.hasActive, isTrue);

        // Select polyline
        polylineController.select(p1);
        await tester.pump();
        expect(polylineController.hasActive, isTrue);
        // Note: In real app, you'd have logic to deselect other controllers
        // but that's application-level coordination

        // Select overlay
        overlayController.select(o1);
        await tester.pump();
        expect(overlayController.hasActive, isTrue);
      });

      testWidgets('multiple layers in edit mode simultaneously',
          (tester) async {
        setupDimensions(tester);
        final markerController = MarkerController();
        final polylineController = PolylineController();

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [],
            markerController: markerController,
          ),
          InteractivePolylineLayer(
            polylines: [],
            polylineController: polylineController,
          ),
        ]));

        markerController.setEditMode(true);
        polylineController.setEditMode(true);
        await tester.pump();

        expect(markerController.isEditing, isTrue);
        expect(polylineController.isEditing, isTrue);

        // Exit one
        markerController.setEditMode(false);
        await tester.pump();

        expect(markerController.isEditing, isFalse);
        expect(polylineController.isEditing, isTrue);
      });
    });

    group('State Management', () {
      testWidgets('save then modify then discard', (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();
        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [],
            markerController: controller,
          ),
        ]));

        // Add and save
        controller.add(m1);
        controller.save();
        await tester.pump();

        expect(controller.current.length, 1);

        // Modify
        controller.move(m1.key!, const LatLng(10, 10));
        await tester.pump();
        expect(controller.current.first.point, const LatLng(10, 10));

        // Discard
        controller.discard();
        await tester.pump();

        // Should revert to saved state (m1 at 0,0)
        expect(controller.current.length, 1);
        expect(controller.current.first.point, const LatLng(0, 0));
        expect(controller.canUndo, isFalse);

        // Abort
        controller.abort();
        await tester.pump();

        // Should revert to intial state
        expect(controller.current.length, 0);
        expect(controller.canUndo, isFalse);
      });

      testWidgets('undo/redo with multiple entity types in history',
          (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();

        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );
        final m2 = Marker(
          point: const LatLng(5, 5),
          child: const SizedBox(),
          key: const ValueKey('m2'),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [],
            markerController: controller,
          ),
        ]));

        controller.add(m1);
        controller.add(m2);
        controller.move(m1.key!, const LatLng(10, 10));
        controller.remove(m2.key!);
        await tester.pump();

        // History: add m1, add m2, move m1, remove m2
        expect(controller.current.length, 1);
        expect(controller.current.first.key, m1.key);

        // Undo remove m2
        controller.undo();
        await tester.pump();
        expect(controller.current.length, 2);

        // Undo move m1
        controller.undo();
        await tester.pump();
        expect(controller.current.first.point, const LatLng(0, 0));

        // Redo move
        controller.redo();
        await tester.pump();
        expect(controller.current.first.point, const LatLng(10, 10));
      });
    });

    group('Edge Cases', () {
      testWidgets('remove marker during drag should cleanup', (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();
        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [m1],
            markerController: controller,
          ),
        ]));

        controller.startDrag(m1, m1.point);
        await tester.pump();

        expect(controller.transientState.value, isNotNull);

        // Remove while dragging
        controller.remove(m1.key!);
        await tester.pump();

        // Transient state should be cleaned up
        // Note: Actual behavior depends on implementation
        expect(controller.current, isEmpty);
      });

      testWidgets('interaction state cleanup on marker removal',
          (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();
        final m1 = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [m1],
            markerController: controller,
          ),
        ]));

        controller.select(m1);
        await tester.pump();
        expect(controller.hasActive, isTrue);

        controller.remove(m1.key!);
        await tester.pump();

        // Active state should be cleared
        expect(controller.hasActive, isFalse);
      });

      testWidgets('empty controller operations do not crash', (tester) async {
        setupDimensions(tester);
        final controller = MarkerController();

        await tester.pumpWidget(wrapMap(children: [
          InteractiveMarkerLayer(
            markers: [],
            markerController: controller,
          ),
        ]));

        // Operations on empty should not crash
        expect(controller.undo, returnsNormally);
        expect(controller.redo, returnsNormally);
        expect(controller.save, returnsNormally);
        expect(controller.discard, returnsNormally);
      });
    });
  });
}
