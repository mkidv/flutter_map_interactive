import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/interactive_scope.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/interactive_marker_scope.dart';
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/interactive_overlay_scope.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_map_interactive/polylines/controllers/polyline_controller.dart';
import 'package:flutter_map_interactive/polylines/interactive_polyline_scope.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scope Options Propagation', () {
    testWidgets('InteractiveMarkerScope propagates options', (tester) async {
      final controller = MarkerController();
      const options = InteractiveOptions<Marker>();

      await tester.pumpWidget(
        MaterialApp(
          home: InteractiveMarkerScope(
            controller: controller,
            builder: (context, markers) {
              final scope = context.dependOnInheritedWidgetOfExactType<
                  InheritedInteractiveScope<Marker>>();
              expect(scope?.options, options);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('InteractivePolylineScope propagates options', (tester) async {
      final controller = PolylineController();
      const options = InteractiveOptions<InteractivePolyline>();

      await tester.pumpWidget(
        MaterialApp(
          home: InteractivePolylineScope(
            controller: controller,
            builder: (context, polylines) {
              final scope = context.dependOnInheritedWidgetOfExactType<
                  InheritedInteractiveScope<InteractivePolyline>>();
              expect(scope?.options, options);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('InteractiveOverlayScope propagates options', (tester) async {
      final controller = OverlayController();
      const options = InteractiveOptions<InteractiveOverlayImage>();

      await tester.pumpWidget(
        MaterialApp(
          home: InteractiveOverlayScope(
            controller: controller,
            builder: (context, overlays) {
              final scope = context.dependOnInheritedWidgetOfExactType<
                  InheritedInteractiveScope<InteractiveOverlayImage>>();
              expect(scope?.options, options);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
