import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'test_app_wrapper.dart';

void main() {
  testWidgets(
      'CollisionLayoutBuilder recomputes placement when nodes change '
      'with same count', (tester) async {
    setupDimensions(tester);

    Widget buildWith(Size size) {
      return wrapMap(
        children: [
          CollisionLayoutBuilder<String>(
            options: const CollisionOptions(
              avoidCollisions: false,
              drawConnectors: false,
            ),
            buildNodes: (context, cam) {
              return [
                CollisionNode<String>(
                  key: const ValueKey('a'),
                  anchor: const LatLng(0, 0),
                  alignment: Alignment.topLeft,
                  knownSize: size,
                  drawConnector: false,
                  data: 'a',
                ),
              ];
            },
            builder: (context, cam, node, placement) {
              return Text(
                '${node.data}:${placement.centerPx.dx.round()}',
                key: const ValueKey('placement'),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ],
      );
    }

    await tester.pumpWidget(buildWith(const Size(80, 24)));
    await tester.pump();

    final first = tester.widget<Text>(find.byKey(const ValueKey('placement')));
    final firstValue = first.data;

    await tester.pumpWidget(buildWith(const Size(140, 24)));
    await tester.pump();

    final second = tester.widget<Text>(find.byKey(const ValueKey('placement')));
    final secondValue = second.data;

    expect(secondValue, isNot(equals(firstValue)));
  });
}
