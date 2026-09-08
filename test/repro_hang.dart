// ignore_for_file: avoid_print

import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('Repro Hang: Small Dataset', () async {
    final controller = MarkerController();
    final itemCount = 10;
    final markers = List.generate(
      itemCount,
      (i) => InteractiveMarker(
        key: ValueKey('m_$i'),
        point: LatLng(0 + (i * 0.001), 0 + (i * 0.001)),
        child: const SizedBox(),
      ),
    );

    print('Setting items...');
    controller.setMarkers(markers, resetHistory: true);
    print('Items set.');

    final targetKey = ValueKey('m_5');
    final original = controller.findByKey(targetKey)!;
    final updated = original.copyWith(point: const LatLng(10, 10));

    print('Updating item...');
    controller.update(targetKey, updated);
    print('Item updated.');

    controller.dispose();
  });
}
