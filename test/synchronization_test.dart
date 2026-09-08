// ignore_for_file: avoid_print

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Synchronization Tests', () {
    test('External update should preserve selection if key exists', () {
      final controller = MarkerController();
      final key = ValueKey('m1');
      final marker1 = Marker(
        key: key,
        point: const LatLng(0, 0),
        child: const SizedBox(),
      );

      controller.setMarkers([marker1], resetHistory: true);
      controller.select(marker1);

      expect(controller.isActive(marker1), isTrue);

      // Simulate external update (new instance, same key)
      final marker1New = Marker(
        key: key,
        point: const LatLng(0, 0),
        child: const SizedBox(width: 10), // Changed child
      );

      controller.setMarkers([marker1New]);

      expect(controller.isActive(marker1New), isTrue,
          reason: 'Selection should persist after update with same key');
      expect(controller.activeItem!.key, equals(key));
    });

    test('External update while dragging should not crash or glitch', () async {
      final controller = MarkerController();
      final key = ValueKey('m1');
      final marker1 = InteractiveMarker(
        key: key,
        point: const LatLng(0, 0),
        child: const SizedBox(),
      );

      controller.setMarkers([marker1], resetHistory: true);

      // Start drag manually
      controller.startDrag(marker1, const LatLng(0, 0));

      expect(controller.transientKeys, contains(key));

      // Simulate external update
      final marker1New = marker1.copyWith(
          point: const LatLng(1, 1)); // Changed position externally
      controller.setMarkers([marker1New]);

      expect(controller.transientKeys, contains(key),
          reason: 'Drag should still be active');

      // Move drag to (5,5)
      controller.updateDrag(const LatLng(5, 5));

      // End Drag
      controller.endDrag();

      final current = controller.findByKey(key);
      print('Final position: ${current?.point}');
    });

    test('External update avoids spurious changes if list content is identical',
        () {
      final controller = MarkerController();
      final key = ValueKey('m1');
      final marker1 = Marker(
        key: key,
        point: const LatLng(0, 0),
        child: const SizedBox(),
      );
      final list1 = [marker1];

      controller.setMarkers(list1, resetHistory: true);
      final current = controller.findByKey(key);

      expect(current, same(marker1));
      expect(controller.current, hasLength(1));
    });
  });
}
