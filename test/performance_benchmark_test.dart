// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_map_interactive/overlays/layers/overlay_handle_layer.dart';
import 'package:flutter_map_interactive/polylines/layers/polyline_handle_layer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'common/test_app_wrapper.dart';
import 'common/test_image.dart';

void main() {
  test('Benchmark: MarkerController Performance with 5,000 items', () async {
    final controller = MarkerController();
    final itemCount = 5000;
    final markers = List.generate(
      itemCount,
      (i) => InteractiveMarker(
        key: ValueKey('m_$i'),
        point: LatLng(0 + (i * 0.001), 0 + (i * 0.001)),
        child: const SizedBox(),
      ),
    );

    print('Starting Add...');
    // 1. Benchmark Bulk Add (via setItems)
    final stopwatch = Stopwatch()..start();
    controller.setMarkers(markers, resetHistory: true);
    stopwatch.stop();
    print('Benchmark [Add $itemCount]: ${stopwatch.elapsedMilliseconds}ms');

    // 2. Benchmark Single Update (Simulating dragging)
    // We update one item in the middle of the list
    final targetKey = ValueKey('m_${itemCount ~/ 2}');
    final original = controller.findByKey(targetKey)!;
    final updated = original.copyWith(point: const LatLng(10, 10));

    print('Starting Update...');
    stopwatch.reset();
    stopwatch.start();
    controller.update(targetKey, updated);
    stopwatch.stop();
    print('Benchmark [Update 1 item]: ${stopwatch.elapsedMilliseconds}ms');

    print('Starting Undo...');
    // 3. Benchmark Undo
    stopwatch.reset();
    stopwatch.start();
    controller.undo();
    stopwatch.stop();
    print('Benchmark [Undo]: ${stopwatch.elapsedMilliseconds}ms');

    // Cleanup
    controller.dispose();
  });

  test('Benchmark: PolylineController Performance with 2,000 items', () async {
    final controller = PolylineController();
    const itemCount = 2000;
    final polylines = List.generate(
      itemCount,
      (i) => InteractivePolyline.safe(
        key: ValueKey('p_$i'),
        points: List.generate(
          8,
          (j) => LatLng(
            i * 0.0005 + j * 0.0002,
            i * 0.0005 + j * 0.0002,
          ),
        ),
        color: Colors.blue,
      ),
    );

    final stopwatch = Stopwatch()..start();
    controller.setPolylines(polylines, resetHistory: true);
    stopwatch.stop();
    print('Benchmark [Polyline setItems $itemCount]: '
        '${stopwatch.elapsedMilliseconds}ms');

    final targetKey = ValueKey('p_${itemCount ~/ 2}');
    final target = controller.findByKey(targetKey)!;

    stopwatch
      ..reset()
      ..start();
    controller.movePoint(
      key: targetKey,
      index: 4,
      from: target.points[4],
      to: LatLng(
        target.points[4].latitude + 0.01,
        target.points[4].longitude + 0.01,
      ),
      merge: true,
    );
    stopwatch.stop();
    print('Benchmark [Polyline movePoint]: ${stopwatch.elapsedMilliseconds}ms');

    stopwatch
      ..reset()
      ..start();
    controller.move(targetKey, const LatLng(12, 12));
    stopwatch.stop();
    print(
        'Benchmark [Polyline move shape]: ${stopwatch.elapsedMilliseconds}ms');

    stopwatch
      ..reset()
      ..start();
    controller.undo();
    stopwatch.stop();
    print('Benchmark [Polyline undo]: ${stopwatch.elapsedMilliseconds}ms');

    controller.dispose();
  });

  test('Benchmark: OverlayController Performance with 1,000 items', () async {
    final controller = OverlayController();
    const itemCount = 1000;
    final overlays = List.generate(
      itemCount,
      (i) {
        final base = i * 0.001;
        return InteractiveOverlayImage.safe(
          key: ValueKey('o_$i'),
          image: kTestImage,
          topLeft: LatLng(base + 0.01, base),
          topRight: LatLng(base + 0.01, base + 0.01),
          bottomRight: LatLng(base, base + 0.01),
          bottomLeft: LatLng(base, base),
        );
      },
    );

    final stopwatch = Stopwatch()..start();
    controller.setOverlays(overlays, resetHistory: true);
    stopwatch.stop();
    print('Benchmark [Overlay setItems $itemCount]: '
        '${stopwatch.elapsedMilliseconds}ms');

    final targetKey = ValueKey('o_${itemCount ~/ 2}');

    stopwatch
      ..reset()
      ..start();
    controller.moveCorner(
      targetKey,
      QuadCorner.topRight,
      const LatLng(5, 5),
      merge: true,
    );
    stopwatch.stop();
    print('Benchmark [Overlay moveCorner]: ${stopwatch.elapsedMilliseconds}ms');

    stopwatch
      ..reset()
      ..start();
    controller.rotate(targetKey, 0.2);
    stopwatch.stop();
    print('Benchmark [Overlay rotate]: ${stopwatch.elapsedMilliseconds}ms');

    stopwatch
      ..reset()
      ..start();
    controller.undo();
    stopwatch.stop();
    print('Benchmark [Overlay undo]: ${stopwatch.elapsedMilliseconds}ms');

    controller.dispose();
  });

  testWidgets('Benchmark: Polyline handle layer activation', (tester) async {
    setupDimensions(tester);
    final controller = PolylineController();
    final polylines = List.generate(
      300,
      (i) => InteractivePolyline.safe(
        key: ValueKey('hp_$i'),
        points: [
          LatLng(i * 0.0004, i * 0.0004),
          LatLng(i * 0.0004 + 0.005, i * 0.0004 + 0.005),
        ],
        color: Colors.orange,
      ),
    );

    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(
      wrapMap(
        children: [
          InteractivePolylineLayer(
            polylines: polylines,
            polylineController: controller,
          ),
        ],
      ),
    );
    stopwatch.stop();
    print('Benchmark [Polyline layer initial pump]: '
        '${stopwatch.elapsedMilliseconds}ms');

    controller.select(polylines.first);
    controller.startEditMode();

    stopwatch
      ..reset()
      ..start();
    await tester.pump();
    stopwatch.stop();
    print('Benchmark [Polyline handles visible]: '
        '${stopwatch.elapsedMilliseconds}ms');

    expect(find.byType(PolylineHandleLayer), findsOneWidget);

    controller.dispose();
  });

  testWidgets('Benchmark: Overlay handle layer activation', (tester) async {
    setupDimensions(tester);
    final controller = OverlayController();
    final overlays = List.generate(
      150,
      (i) {
        final base = i * 0.001;
        return InteractiveOverlayImage.safe(
          key: ValueKey('ho_$i'),
          image: kTestImage,
          topLeft: LatLng(base + 0.01, base),
          topRight: LatLng(base + 0.01, base + 0.01),
          bottomRight: LatLng(base, base + 0.01),
          bottomLeft: LatLng(base, base),
        );
      },
    );

    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(
      wrapMap(
        children: [
          InteractiveOverlayLayer(
            overlays: overlays,
            overlayController: controller,
          ),
        ],
      ),
    );
    stopwatch.stop();
    print('Benchmark [Overlay layer initial pump]: '
        '${stopwatch.elapsedMilliseconds}ms');

    controller.select(overlays.first);
    controller.startEditMode();

    stopwatch
      ..reset()
      ..start();
    await tester.pump();
    stopwatch.stop();
    print('Benchmark [Overlay handles visible]: '
        '${stopwatch.elapsedMilliseconds}ms');

    expect(find.byType(OverlayHandleLayer), findsOneWidget);

    controller.dispose();
  });
}
