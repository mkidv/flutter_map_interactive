import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide InteractionOptions;
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/markers/models/options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MarkerController', () {
    late MarkerController controller;
    final m1 = Marker(
        point: const LatLng(0, 0),
        child: const SizedBox(),
        key: const ValueKey('m1'));

    setUp(() {
      controller = MarkerController();
      controller.setMarkers([], resetHistory: true);
    });

    test('add adds marker', () {
      controller.add(m1);
      expect(controller.current, contains(m1));
      expect(controller.canUndo, isTrue);
    });

    test('remove removes marker and cleans interactions', () {
      controller.add(m1);
      controller.select(m1);

      expect(controller.hasActive, isTrue);

      controller.remove(m1.key!);
      expect(controller.current, isEmpty);
      expect(controller.hasActive, isFalse);
    });

    test('update modifies marker', () {
      controller.add(m1);

      final updated = Marker(
          point: const LatLng(1, 1),
          child: const SizedBox(),
          key: const ValueKey('m1'));
      controller.update(m1.key!, updated);

      expect(controller.current.first.point, const LatLng(1, 1));
      expect(controller.current.first.key, m1.key);
    });

    test('move updates position', () {
      controller.add(m1);
      controller.move(m1.key!, const LatLng(5, 5));

      expect(controller.current.first.point, const LatLng(5, 5));
    });

    group('Drag Interaction', () {
      setUp(() {
        controller.add(m1);
      });

      test('startDrag hides original and sets transient state', () {
        controller.startDrag(m1, m1.point);

        expect(controller.transientKeys, contains(m1.key));
        expect(controller.transientState.value, isNotNull);
        expect(controller.transientState.value!.item, m1);
      });

      test('updateDrag moves transient marker', () {
        controller.startDrag(m1, m1.point);
        controller.updateDrag(const LatLng(2, 2));

        expect(controller.transientState.value!.current, const LatLng(2, 2));
        // Original still at 0,0
        expect(controller.current.first.point, const LatLng(0, 0));
      });

      test('endDrag commits move', () {
        controller.startDrag(m1, m1.point);
        controller.updateDrag(const LatLng(2, 2));
        controller.endDrag();

        expect(controller.transientState.value, isNull);
        expect(controller.transientKeys, isEmpty);
        expect(controller.current.first.point, const LatLng(2, 2));
      });
    });

    group('Interaction Options', () {
      test('selectMarker invokes callbacks', () {
        Marker? active;
        controller.setOptions(InteractiveOptions(
          onActive: (m) => active = m,
        ));

        controller.add(m1);
        controller.select(m1);

        expect(controller.isActive(m1), isTrue);
        expect(active, m1);
      });

      test('enhanced marker gesture options are called', () {
        bool tapped = false;
        final em = InteractiveMarker(
          point: const LatLng(0, 0),
          child: const SizedBox(),
          key: const ValueKey('em'),
          options: [
            GestureMarkerOptions(onTap: () => tapped = true),
          ],
        );

        controller.add(em);
        controller.tap(em);

        expect(tapped, isTrue);
        expect(controller.isActive(em), isTrue); // Tap also selects by default
      });
    });
  });
}
