import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_map_interactive_example/widgets/control_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('delete, undo, save and discard operate on the selected scene',
      (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MarkerController();
    addTearDown(controller.dispose);
    const first = Marker(
        key: ValueKey('first'), point: LatLng(0, 0), child: Icon(Icons.place));
    const second = Marker(
        key: ValueKey('second'), point: LatLng(1, 1), child: Icon(Icons.place));
    controller.setMarkers([first], resetHistory: true);
    var saves = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DemoControls(
      controller: controller,
      onAdd: () {
        controller.add(second);
        controller.select(second);
      },
      onReset: () {},
      onCenter: () {},
      onSaved: () => saves++,
    ))));
    final deleteButton = find.widgetWithText(OutlinedButton, 'Delete selected');
    expect(tester.widget<OutlinedButton>(deleteButton).onPressed, isNull);
    await tester.tap(find.text('Add at center'));
    await tester.pump();
    expect(controller.current, hasLength(2));
    await tester.tap(find.text('Save checkpoint'));
    await tester.pump();
    expect(saves, 1);
    expect(controller.hasUnsavedChanges, isFalse);
    await tester.tap(find.text('Delete selected'));
    await tester.pump();
    expect(controller.current, hasLength(1));
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(controller.current, hasLength(2));
    await tester.tap(find.text('Redo'));
    await tester.pump();
    expect(controller.current, hasLength(1));
    await tester.tap(find.text('Discard changes'));
    await tester.pump();
    expect(controller.current, hasLength(2));
    expect(controller.hasUnsavedChanges, isFalse);
    expect(tester.takeException(), isNull);
  });
}
