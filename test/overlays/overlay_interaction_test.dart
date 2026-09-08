import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_app_wrapper.dart';
import '../common/test_image.dart';

void main() {
  group('InteractiveOverlayLayer', () {
    final o1 = InteractiveOverlayImage.safe(
      key: const ValueKey('o1'),
      image: kTestImage,
      topLeft: const LatLng(10, 0),
      topRight: const LatLng(10, 10),
      bottomRight: const LatLng(0, 10),
      bottomLeft: const LatLng(0, 0),
    );

    testWidgets('renders overlays', (tester) async {
      setupDimensions(tester);
      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveOverlayLayer(overlays: [o1]),
        ],
      ));

      expect(find.byType(OverlayLayer), findsOneWidget);
      // OverlayLayer paints on canvas, so finding widgets inside is hard unless we check for specific render object interactions
      // But we can check if OverlayGestureLayer is present
      expect(find.byType(OverlayGestureLayer), findsOneWidget);
    });

    testWidgets('shows handles in edit mode', (tester) async {
      setupDimensions(tester);
      final controller = OverlayController();

      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveOverlayLayer(
            overlays: [o1],
            overlayController: controller,
          ),
        ],
      ));

      expect(find.byType(OverlayHandleLayer), findsNothing);

      controller.setEditMode(true);
      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveOverlayLayer(
            overlays: [o1],
            overlayController: controller,
          ),
        ],
      ));
      await tester.pump(); // Frame update

      expect(find.byType(OverlayHandleLayer), findsOneWidget);
    });

    testWidgets('only renders one handle marker layer for the active overlay',
        (tester) async {
      setupDimensions(tester);
      final controller = OverlayController();
      final o2 = InteractiveOverlayImage.safe(
        key: const ValueKey('o2'),
        image: kTestImage,
        topLeft: const LatLng(0.02, -0.02),
        topRight: const LatLng(0.02, 0.02),
        bottomRight: const LatLng(-0.02, 0.02),
        bottomLeft: const LatLng(-0.02, -0.02),
      );

      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveOverlayLayer(
            overlays: [o1, o2],
            overlayController: controller,
          ),
        ],
      ));

      controller.select(o2);
      controller.setEditMode(true);
      await tester.pump();

      expect(find.byType(OverlayHandleLayer), findsOneWidget);
      expect(find.byType(InteractiveMarkerLayer), findsOneWidget);
    });
  });
}
