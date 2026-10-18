import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_map_interactive_example/pages/demo_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _LocalTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/plan.png');
}

Future<void> _mount(WidgetTester tester,
    {Size size = const Size(1200, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester
      .pumpWidget(MaterialApp(home: DemoPage(tileProvider: _LocalTiles())));
  await tester.pumpAndSettle(const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
}

void main() {
  testWidgets(
      'dataset changes reach the controller and scene changes keep history',
      (tester) async {
    await _mount(tester);
    final layer = tester
        .widget<InteractiveMarkerLayer>(find.byType(InteractiveMarkerLayer));
    final controller = layer.markerController!;
    expect(controller.current, hasLength(16));

    await tester.tap(find.text('Add at center'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(17));
    expect(controller.canUndo, isTrue);

    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    await tester.tap(find.text('Pins'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(17));
    expect(controller.canUndo, isTrue);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(16));

    await tester.scrollUntilVisible(find.text('Dense dataset (16 pins)'), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Dense dataset (16 pins)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(7));
    expect(controller.canUndo, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay edits survive settings and scene changes',
      (tester) async {
    await _mount(tester);
    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    final layer = tester
        .widget<InteractiveOverlayLayer>(find.byType(InteractiveOverlayLayer));
    final controller = layer.overlayController!;
    await tester.tap(find.text('Add at center'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(2));
    final addedKey = controller.activeKey!;
    controller.move(addedKey, const LatLng(48.112, -1.681));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    final corners = controller.findByKey(addedKey)!.corners;

    await tester.scrollUntilVisible(find.byType(Slider), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.drag(find.byType(Slider), const Offset(-30, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(2));
    expect(controller.findByKey(addedKey)!.corners, corners);

    await tester.scrollUntilVisible(find.text('Lines'), -150,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Lines'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(2));
    expect(controller.findByKey(addedKey)!.corners, corners);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mobile controls scroll without overflow and resizing keeps state',
      (tester) async {
    await _mount(tester, size: const Size(390, 844));
    final controller = tester
        .widget<InteractiveMarkerLayer>(find.byType(InteractiveMarkerLayer))
        .markerController!;
    controller.add(const Marker(
      key: ValueKey('resize-test'),
      point: LatLng(48.111, -1.680),
      child: Icon(Icons.location_on),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(17));
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(controller.current, hasLength(17));
    expect(controller.canUndo, isTrue);
    expect(tester.takeException(), isNull);
  });
}
