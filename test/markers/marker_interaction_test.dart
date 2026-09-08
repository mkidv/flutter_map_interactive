import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MarkerLayer;
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_app_wrapper.dart';

void main() {
  group('InteractiveMarkerLayer', () {
    testWidgets('renders markers', (tester) async {
      setupDimensions(tester);
      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveMarkerLayer(
            markers: [
              Marker(
                point: const LatLng(0, 0),
                child: const SizedBox(width: 30, height: 30),
                key: const ValueKey('m1'),
              ),
            ],
          ),
        ],
      ));

      expect(find.byKey(const ValueKey('m1')), findsOneWidget);
    });

    testWidgets('updates markers when widget updates', (tester) async {
      setupDimensions(tester);
      await tester.pumpWidget(wrapMap(
        children: [
          const InteractiveMarkerLayer(markers: []),
        ],
      ));
      expect(find.byType(MarkerLayer),
          findsOneWidget); // MarkerLayer is always present? Or empty?

      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveMarkerLayer(
            markers: [
              Marker(
                point: const LatLng(0, 0),
                child: const SizedBox(width: 30, height: 30),
                key: const ValueKey('m1'),
              ),
            ],
          ),
        ],
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('m1')), findsOneWidget);
    });

    testWidgets('handles interaction options', (tester) async {
      setupDimensions(tester);
      bool tapped = false;
      final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(width: 30, height: 30),
          key: const ValueKey('m1'),
          options: [
            GestureMarkerOptions(onTap: () {
              tapped = true;
            })
          ]);

      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveMarkerLayer(
            markers: [marker],
            markerOptions: const InteractiveLayerOptions(),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 300));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('shows popup when configured', (tester) async {
      setupDimensions(tester);
      final marker = InteractiveMarker(
        point: const LatLng(0, 0),
        child: const SizedBox(width: 30, height: 30),
        key: const ValueKey('m1'),
        options: [
          const PopupMarkerOptions(popup: Text('Popup')),
        ],
      );

      final controller = MarkerController();

      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveMarkerLayer(
            markers: [marker],
            markerController: controller,
            popupOptions:
                const PopupLayerOptions(), // Must provide options to enable layer
          ),
        ],
      ));

      // Select marker to show popup
      controller.toggleSelect(marker);
      await tester.pumpAndSettle();

      expect(find.text('Popup'), findsOneWidget);
    });

    testWidgets('moveOnTap moves selected marker then deselects',
        (tester) async {
      setupDimensions(tester);
      final controller = MarkerController();
      final marker = Marker(
        point: const LatLng(0, 0),
        child: const SizedBox(width: 30, height: 30),
        key: const ValueKey('m1'),
      );

      await tester.pumpWidget(wrapMap(
        children: [
          InteractiveMarkerLayer(
            markers: [marker],
            markerController: controller,
            options: const InteractiveOptions<Marker>(
              moveOnTap: true,
              centerOnTap: false,
            ),
          ),
        ],
      ));

      controller.select(marker);
      controller.startEditMode();
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(500, 300));
      await tester.pumpAndSettle();

      expect(controller.hasActive, isFalse);
      expect(controller.current.first.point, isNot(const LatLng(0, 0)));
    });
  });
}
