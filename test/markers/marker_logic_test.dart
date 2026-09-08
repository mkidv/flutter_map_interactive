import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/markers/controllers/op.dart';
import 'package:flutter_map_interactive/markers/logic/marker_logic.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/markers/models/options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MarkerLogic', () {
    late MarkerLogic logic;
    late InteractiveOptions<Marker> options;

    setUp(() {
      options = const InteractiveOptions<Marker>();
      logic = MarkerLogic(() => options);
    });

    group('Key Management', () {
      test('getItemKey returns marker key', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        expect(logic.getItemKey(marker), const ValueKey('m1'));
      });

      test('getItemKey returns null when marker has no key', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
        );

        expect(logic.getItemKey(marker), isNull);
      });

      test('ensureHasKey generates throw when marker has no key', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
        );

        expect(() => logic.ensureHasKey(marker), throwsArgumentError);
      });
    });

    group('Spatial Change Detection', () {
      test('hasSpatialChange detects position change', () {
        final oldMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
        );
        final newMarker = Marker(
          point: const LatLng(5, 5),
          child: const SizedBox(),
        );

        expect(logic.hasSpatialChange(oldMarker, newMarker), isTrue);
      });

      test('hasSpatialChange detects width change', () {
        final oldMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          width: 10,
        );
        final newMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          width: 20,
        );

        expect(logic.hasSpatialChange(oldMarker, newMarker), isTrue);
      });

      test('hasSpatialChange detects height change', () {
        final oldMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          height: 10,
        );
        final newMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          height: 20,
        );

        expect(logic.hasSpatialChange(oldMarker, newMarker), isTrue);
      });

      test('hasSpatialChange returns false when markers identical', () {
        final oldMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          width: 10,
          height: 10,
        );
        final newMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          width: 10,
          height: 10,
        );

        expect(logic.hasSpatialChange(oldMarker, newMarker), isFalse);
      });

      test('hasSpatialChange ignores non-spatial changes', () {
        final oldMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          rotate: false,
        );
        final newMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          rotate: true,
        );

        expect(logic.hasSpatialChange(oldMarker, newMarker), isFalse);
      });
    });

    group('Operation Creation', () {
      test('createAddOp creates MarkerOp.add', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        final op = logic.createAddOp(marker);

        expect(op, isA<MarkerOp>());
        // Verify it's an add operation through its behavior
        final items = <Marker>[];
        op.apply(items);
        expect(items, contains(marker));
      });

      test('createRemoveOp creates MarkerOp.remove', () {
        const key = ValueKey('m1');
        final op = logic.createRemoveOp(key);

        expect(op, isA<MarkerOp>());
      });

      test('createUpdateOp creates MarkerOp.update', () {
        final oldMarker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );
        final newMarker = Marker(
          point: const LatLng(5, 5),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );

        final op = logic.createUpdateOp(oldMarker, newMarker);

        expect(op, isA<MarkerOp>());
      });

      test('createDragEndOp creates Move operation', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('m1'),
        );
        const origin = LatLng(0, 0);
        const current = LatLng(5, 5);

        final op = logic.createDragEndOp(marker, origin, current);

        expect(op, isNotNull);
        expect(op, isA<MarkerOp>());

        // Verify the operation moves the marker
        final items = [marker];
        op!.apply(items);
        expect(items.first.point, current);
      });

      test('createDragEndOp returns null when marker has no key', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
        );
        const origin = LatLng(0, 0);
        const current = LatLng(5, 5);

        final op = logic.createDragEndOp(marker, origin, current);

        expect(op, isNull);
      });
    });

    group('Interaction Callbacks', () {
      test('onInteraction invokes onTap for InteractiveMarker', () {
        bool tapped = false;
        final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          options: [
            GestureMarkerOptions(onTap: () => tapped = true),
          ],
        );

        logic.onInteraction(marker, InteractionType.tap);

        expect(tapped, isTrue);
      });

      test('onInteraction invokes onHover for InteractiveMarker', () {
        bool hovered = false;
        final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          options: [
            GestureMarkerOptions(onHover: () => hovered = true),
          ],
        );

        logic.onInteraction(marker, InteractionType.hover);

        expect(hovered, isTrue);
      });

      test('onInteraction invokes onLongPress for InteractiveMarker', () {
        bool longPressed = false;
        final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          options: [
            GestureMarkerOptions(onLongPress: () => longPressed = true),
          ],
        );

        logic.onInteraction(marker, InteractionType.longPress);

        expect(longPressed, isTrue);
      });

      test('onInteraction handles active type without error', () {
        final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
        );

        // Should not throw
        expect(
          () => logic.onInteraction(marker, InteractionType.active),
          returnsNormally,
        );
      });

      test('onInteraction does nothing for standard Marker', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
        );

        // Should not throw
        expect(
          () => logic.onInteraction(marker, InteractionType.tap),
          returnsNormally,
        );
      });

      test('onInteraction handles null callbacks gracefully', () {
        final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          options: [
            const GestureMarkerOptions(), // No callbacks set
          ],
        );

        expect(
          () => logic.onInteraction(marker, InteractionType.tap),
          returnsNormally,
        );
      });
    });

    group('Drag Updates', () {
      test('onDragUpdate invokes onPositionChanged for InteractiveMarker', () {
        LatLng? capturedOrigin;
        LatLng? capturedCurrent;

        final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          options: [
            GestureMarkerOptions(
              onPositionChanged: (origin, current) {
                capturedOrigin = origin;
                capturedCurrent = current;
              },
            ),
          ],
        );

        const origin = LatLng(0, 0);
        const current = LatLng(5, 5);

        logic.onDragUpdate(marker, origin, current);

        expect(capturedOrigin, origin);
        expect(capturedCurrent, current);
      });

      test('onDragUpdate does nothing for standard Marker', () {
        final marker = Marker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
        );

        expect(
          () => logic.onDragUpdate(
              marker, const LatLng(0, 0), const LatLng(5, 5)),
          returnsNormally,
        );
      });

      test('onDragUpdate handles null callback gracefully', () {
        final marker = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          options: const [
            GestureMarkerOptions(), // No onPositionChanged set
          ],
        );

        expect(
          () => logic.onDragUpdate(
              marker, const LatLng(0, 0), const LatLng(5, 5)),
          returnsNormally,
        );
      });
    });
  });
}
