import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Wraps the test layer in a MaterialApp and Scaffold with a FlutterMap.
Widget wrapMap({
  required List<Widget> children,
  MapOptions? options,
  MapController? mapController,
}) {
  return MaterialApp(
    home: Scaffold(
      body: FlutterMap(
        mapController: mapController,
        options: options ??
            const MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 10,
            ),
        children: children,
      ),
    ),
  );
}

/// Sets up standard screen dimensions for consistent hit testing.
void setupDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
