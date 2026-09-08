import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_app_wrapper.dart';

void main() {
  group('InteractivePolylineLayer', () {
    final p1 = InteractivePolyline.safe(
      key: const ValueKey('p1'),
      points: [const LatLng(0, 0), const LatLng(10, 10)],
      color: Colors.blue,
    );

    testWidgets('renders polylines', (tester) async {
      await tester.pumpWidget(wrapMap(children: [
        InteractivePolylineLayer(polylines: [p1]),
      ]));

      // PolylineLayer paints on canvas.
      // We can check if Gesture layer is present
      expect(find.byType(PolylineGestureLayer), findsOneWidget);
    });

    testWidgets('shows handles in edit mode', (tester) async {
      final controller = PolylineController();

      await tester.pumpWidget(wrapMap(children: [
        InteractivePolylineLayer(
          polylines: [p1],
          polylineController: controller,
          // Ensure handles are enabled or default
        ),
      ]));

      expect(find.byType(PolylineHandleLayer), findsNothing);

      controller.setEditMode(true);
      await tester.pumpWidget(wrapMap(children: [
        InteractivePolylineLayer(
          polylines: [p1],
          polylineController: controller,
        ),
      ]));
      await tester.pump(); // Frame update

      // Should now show handles layer
      expect(find.byType(PolylineHandleLayer), findsOneWidget);
    });

    testWidgets('only renders handles for the active polyline', (tester) async {
      setupDimensions(tester);
      final controller = PolylineController();
      final p2 = InteractivePolyline.safe(
        key: const ValueKey('p2'),
        points: [
          const LatLng(-0.01, -0.01),
          const LatLng(0.0, 0.0),
          const LatLng(0.01, 0.01),
        ],
        color: Colors.green,
      );

      await tester.pumpWidget(wrapMap(children: [
        InteractivePolylineLayer(
          polylines: [p1, p2],
          polylineController: controller,
        ),
      ]));

      controller.select(p2);
      controller.setEditMode(true);
      await tester.pump();

      expect(find.byType(PolylineHandleLayer), findsOneWidget);
      expect(find.byType(InteractiveMarkerLayer), findsOneWidget);
    });
    testWidgets('onPolylineTap ', (tester) async {
      setupDimensions(tester);

      final polylines = [
        InteractivePolyline.safe(
          key: const Key('p1'),
          points: [const LatLng(-0.01, -0.01), const LatLng(0.01, 0.01)],
          strokeWidth: 20, // Thick line to ensure hit
          color: Colors.red,
        ),
      ];

      final controller = PolylineController();

      var tapped = false;
      final options = InteractiveOptions<InteractivePolyline>(
        onTap: (p) => tapped = true,
      );

      await tester.pumpWidget(wrapMap(
        children: [
          InteractivePolylineLayer(
            polylines: polylines,
            polylineController: controller,
            options: options,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Tap on center (0,0) where the line passes
      await tester.tapAt(const Offset(400, 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('disabledGestures prevent interaction', (tester) async {
      setupDimensions(tester);

      final polylines = [
        InteractivePolyline.safe(
          key: const Key('p1'),
          points: [const LatLng(-0.01, -0.01), const LatLng(0.01, 0.01)],
          strokeWidth: 20,
          color: Colors.red,
        ),
      ];

      final controller = PolylineController();
      controller.startEditMode();

      var tapped = false;
      final options = InteractiveOptions<InteractivePolyline>(
        enabledGestures: InteractiveEnabledGestures.none(),
        onTap: (p) => tapped = true,
      );

      await tester.pumpWidget(wrapMap(
        children: [
          InteractivePolylineLayer(
            polylines: polylines,
            polylineController: controller,
            options: options,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });
  });
}
