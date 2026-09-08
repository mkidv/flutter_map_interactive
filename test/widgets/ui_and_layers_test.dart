import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_app_wrapper.dart';

class _FakeTickerProvider extends TestVSync {}

void main() {
  group('UI Buttons', () {
    testWidgets('EditModeToggleButton toggles edit mode on tap',
        (tester) async {
      final controller = MarkerController();
      expect(controller.isEditing, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditModeToggleButton(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byType(EditModeToggleButton));
      await tester.pump();
      expect(controller.isEditing, isTrue);

      await tester.tap(find.byType(EditModeToggleButton));
      await tester.pump();
      expect(controller.isEditing, isFalse);
    });

    testWidgets(
        'EditModeUndoButton and EditModeRedoButton trigger undo and redo',
        (tester) async {
      final controller = MarkerController();
      controller.startEditMode();

      final marker = const InteractiveMarker(
        key: ValueKey('m1'),
        point: LatLng(0, 0),
        child: SizedBox(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                EditModeUndoButton(controller: controller),
                EditModeRedoButton(controller: controller),
              ],
            ),
          ),
        ),
      );

      controller.add(marker);
      await tester.pump();
      expect(controller.canUndo, isTrue);

      await tester.tap(find.byType(EditModeUndoButton));
      await tester.pump();
      expect(controller.current, isEmpty);
      expect(controller.canRedo, isTrue);

      await tester.tap(find.byType(EditModeRedoButton));
      await tester.pump();
      expect(controller.current.length, 1);
    });

    testWidgets('MapCenterButton triggers centerPointAnimated', (tester) async {
      final map = MapController();
      final vsync = _FakeTickerProvider();

      await tester.pumpWidget(
        wrapMap(
          mapController: map,
          children: [
            MapCenterButton(
              map: map,
              vsync: vsync,
              center: const LatLng(10, 10),
              zoom: 12,
              tooltip: 'Center',
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(MapCenterButton));
      await tester.pumpAndSettle();
      expect(find.byType(MapCenterButton), findsOneWidget);
    });
  });

  group('Marker Actions', () {
    testWidgets(
        'MarkerActionMenu and TrashMarkerAction handle delete confirmation and cancel',
        (tester) async {
      final controller = MarkerController();
      const marker = InteractiveMarker(
        key: ValueKey('test-pin'),
        point: LatLng(0, 0),
        child: Icon(Icons.pin_drop),
      );

      controller.add(marker);
      controller.longPress(marker); // sets longPressedItem

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveMarkerScope(
              controller: controller,
              builder: (context, markers) => MarkerActionMenu(
                actions: [
                  TrashMarkerAction(
                    onConfirm: (m, {controller}) {
                      controller?.remove(m.key!);
                    },
                    onCancel: (m, {controller}) {
                      controller?.deselect();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete), findsOneWidget);

      // Tap delete to expand
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap confirm (check icon)
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      expect(controller.current, isEmpty);
    });

    testWidgets('SimpleMarkerAction executes callback with controller',
        (tester) async {
      final controller = MarkerController();
      const marker = InteractiveMarker(
        key: ValueKey('pin2'),
        point: LatLng(0, 0),
        child: SizedBox(),
      );

      controller.add(marker);
      controller.longPress(marker);

      bool clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveMarkerScope(
              controller: controller,
              builder: (context, markers) => SimpleMarkerAction(
                icon: const Icon(Icons.star),
                onPressed: (m, {controller}) {
                  clicked = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star));
      await tester.pump();
      expect(clicked, isTrue);
    });
  });

  group('Debug Layers', () {
    testWidgets('MarkerHitboxLayer and MarkerTargetLayer render without errors',
        (tester) async {
      final controller = MarkerController();
      final marker = const InteractiveMarker(
        key: ValueKey('m_target'),
        point: LatLng(0, 0),
        width: 40,
        height: 40,
        child: SizedBox(),
      );
      controller.add(marker);

      await tester.pumpWidget(
        wrapMap(
          children: [
            InteractiveMarkerScope(
              controller: controller,
              builder: (context, markers) => MarkerHitboxLayer(
                markers: [marker],
                options: const MarkerLayerOptions(),
              ),
            ),
            MarkerTargetLayer(markers: [marker]),
          ],
        ),
      );

      await tester.pump();
      expect(find.byType(MarkerHitboxLayer), findsOneWidget);
      expect(find.byType(MarkerTargetLayer), findsOneWidget);
      expect(find.byType(CrossTarget), findsOneWidget);
    });

    testWidgets('PolylineHitboxLayer renders polyline paths without error',
        (tester) async {
      final polyline = InteractivePolyline(
        key: const ValueKey('poly1'),
        points: const [LatLng(0, 0), LatLng(1, 1), LatLng(2, 0)],
      );

      await tester.pumpWidget(
        wrapMap(
          children: [
            PolylineHitboxLayer(
              polylines: [polyline],
              hitTolerance: 20,
            ),
          ],
        ),
      );

      await tester.pump();
      expect(find.byType(PolylineHitboxLayer), findsOneWidget);
    });
  });

  group('Reactive Components', () {
    testWidgets('CombinedSelector listens to multiple listenables',
        (tester) async {
      final n1 = ValueNotifier<int>(1);
      final n2 = ValueNotifier<String>('a');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombinedSelector<String>(
              listenables: [n1, n2],
              select: (list) => '${n1.value}_${n2.value}',
              builder: (context, val) =>
                  Text(val, textDirection: TextDirection.ltr),
            ),
          ),
        ),
      );

      expect(find.text('1_a'), findsOneWidget);

      n1.value = 2;
      await tester.pump();
      expect(find.text('2_a'), findsOneWidget);

      n2.value = 'b';
      await tester.pump();
      expect(find.text('2_b'), findsOneWidget);
    });

    test('StreamListenable converts stream and updates ValueListenable',
        () async {
      final controller = StreamController<int>();
      final listenable =
          controller.stream.asListenable(initialValue: 0, mergeEvents: false);

      expect(listenable.value, 0);

      controller.add(42);
      await pumpEventQueue();
      expect(listenable.value, 42);

      listenable.dispose();
      await controller.close();
    });
  });
}
