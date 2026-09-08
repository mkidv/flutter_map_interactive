import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'common/test_app_wrapper.dart';

void main() {
  group('Common Options & Events', () {
    test('AutoPanOnDragOptions copyWith and equality', () {
      const opt1 = AutoPanOnDragOptions();
      final opt2 = opt1.copyWith(minStepPx: 10, enabled: false);

      expect(opt2.minStepPx, 10);
      expect(opt2.enabled, isFalse);
      expect(opt1 == opt2, isFalse);
      expect(opt1 == opt1.copyWith(), isTrue);
      expect(opt1.hashCode, isNotNull);
    });

    test('InteractiveEnabledGestures copyWith, none, all and equality', () {
      final none = InteractiveEnabledGestures.none();
      expect(none.tap, isFalse);
      expect(none.drag, isFalse);

      final all = InteractiveEnabledGestures.all();
      expect(all.tap, isTrue);
      expect(all.drag, isTrue);

      final modified = all.copyWith(tap: false, hover: false);
      expect(modified.tap, isFalse);
      expect(modified == all, isFalse);
      expect(all == const InteractiveEnabledGestures(), isTrue);
      expect(all.hashCode, isNotNull);
    });

    test('InteractiveOptions copyWith and equality', () {
      const opt = InteractiveOptions<String>(
        moveOnTap: true,
        centerOnTap: false,
        autoSave: true,
      );
      final copy = opt.copyWith(
          moveOnTap: false, autoSaveDelay: const Duration(seconds: 1));

      expect(copy.moveOnTap, isFalse);
      expect(copy.autoSaveDelay, const Duration(seconds: 1));
      expect(opt == copy, isFalse);
      expect(opt == opt.copyWith(), isTrue);
      expect(opt.hashCode, isNotNull);
    });

    test('CollisionOptions copyWith and equality', () {
      const opt = CollisionOptions();
      final copy = opt.copyWith(step: 20, drawConnectors: false);

      expect(copy.step, 20);
      expect(copy.drawConnectors, isFalse);
      expect(opt == copy, isFalse);
      expect(opt == opt.copyWith(), isTrue);
      expect(opt.hashCode, isNotNull);
    });

    test('EntityDelta computes hasChanged and toString', () {
      const delta1 = EntityDelta<String>(
        added: ['b'],
        updated: [],
        removed: [],
      );
      expect(delta1.hasChanged, isTrue);
      expect(delta1.toString(), contains('EntityDelta'));

      const deltaEmpty = EntityDelta<String>(
        added: [],
        updated: [],
        removed: [],
      );
      expect(deltaEmpty.hasChanged, isFalse);

      // Diff test
      final diff = EntityDelta<String>.diff(
        ['a', 'b'],
        ['b', 'c'],
        keySelector: (s) => s,
        hasSpatialChange: (a, b) => false,
      );
      expect(diff.added, ['c']);
      expect(diff.removed, ['a']);
    });

    test('InteractiveEvent toString checks', () {
      expect(ItemTapped('m').toString(), contains('ItemTapped'));
      expect(ItemSelected('m').toString(), contains('ItemSelected'));
      expect(ItemDeselected('m').toString(), contains('ItemDeselected'));
      expect(ItemHovered('m').toString(), contains('ItemHovered'));
      expect(HoverCleared('m').toString(), contains('HoverCleared'));
      expect(ItemLongPressed('m').toString(), contains('ItemLongPressed'));
      expect(
          HistoryChanged<String>(
                  current: [], canUndo: true, canRedo: false, historyDepth: 1)
              .toString(),
          contains('HistoryChanged'));
      expect(DragStarted('m', const LatLng(0, 0)).toString(),
          contains('DragStarted'));
      expect(
          DragUpdated('m', const LatLng(0, 0), const LatLng(1, 1)).toString(),
          contains('DragUpdated'));
      expect(DragEnded('m', const LatLng(0, 0), const LatLng(1, 1)).toString(),
          contains('DragEnded'));
      expect(EditModeChanged<String>(true).toString(),
          contains('EditModeChanged'));
      expect(ItemAdded('m').toString(), contains('ItemAdded'));
      expect(ItemRemoved('m').toString(), contains('ItemRemoved'));
      expect(ItemUpdated('old', 'new').toString(), contains('ItemUpdated'));
    });
  });

  group('Marker Options & Models', () {
    test('MarkerLayerOptions hierarchy copyWith and equality', () {
      const base =
          MarkerLayerOptions(alignment: Alignment.topCenter, rotate: true);
      final baseCopy = base.copyWith(alignment: Alignment.bottomCenter);
      expect(baseCopy.alignment, Alignment.bottomCenter);
      expect(base == baseCopy, isFalse);
      expect(base == base.copyWith(), isTrue);

      const inter =
          InteractiveLayerOptions(activeSizeFactor: 1.2, touchSizeFactor: 1.5);
      final interCopy = inter.copyWith(activeSizeFactor: 1.4);
      expect(interCopy.activeSizeFactor, 1.4);
      expect(inter == interCopy, isFalse);
      expect(inter == inter.copyWith(), isTrue);
      expect(inter.hashCode, isNotNull);

      const popup =
          PopupLayerOptions(animationDuration: Duration(milliseconds: 200));
      final popupCopy = popup.copyWith(margin: const EdgeInsets.all(8));
      expect(popupCopy.margin, const EdgeInsets.all(8));
      expect(popup == popupCopy, isFalse);
      expect(popup == popup.copyWith(), isTrue);
      expect(popup.hashCode, isNotNull);

      const label = LabelLayerOptions(hideOnEdit: true);
      final labelCopy = label.copyWith(hideOnEdit: false);
      expect(labelCopy.hideOnEdit, isFalse);
      expect(label == labelCopy, isFalse);
      expect(label == label.copyWith(), isTrue);
      expect(label.hashCode, isNotNull);

      const action =
          ActionLayerOptions(animationDuration: Duration(milliseconds: 100));
      final actionCopy = action.copyWith(margin: const EdgeInsets.all(4));
      expect(actionCopy.margin, const EdgeInsets.all(4));
      expect(action == actionCopy, isFalse);
      expect(action == action.copyWith(), isTrue);
      expect(action.hashCode, isNotNull);
    });

    test('Marker Model Options copyWith and equality', () {
      const labelOpt = LabelMarkerOptions(label: SizedBox());
      final labelOptCopy = labelOpt.copyWith(rotate: false);
      expect(labelOptCopy.rotate, isFalse);
      expect(labelOpt == labelOptCopy, isFalse);
      expect(labelOpt == labelOpt.copyWith(), isTrue);
      expect(labelOpt.hashCode, isNotNull);

      const popupOpt =
          PopupMarkerOptions(popup: SizedBox(), alignment: Alignment.topLeft);
      final popupOptCopy = popupOpt.copyWith(alignment: Alignment.center);
      expect(popupOptCopy.alignment, Alignment.center);
      expect(popupOpt == popupOptCopy, isFalse);
      expect(popupOpt == popupOpt.copyWith(), isTrue);
      expect(popupOpt.hashCode, isNotNull);

      const actionOpt = ActionMarkerOptions(
          action: SizedBox(), alignment: Alignment.centerLeft);
      final actionOptCopy =
          actionOpt.copyWith(alignment: Alignment.bottomRight);
      expect(actionOptCopy.alignment, Alignment.bottomRight);
      expect(actionOpt == actionOptCopy, isFalse);
      expect(actionOpt == actionOpt.copyWith(), isTrue);
      expect(actionOpt.hashCode, isNotNull);

      const activeOpt =
          ActiveMarkerOptions(active: SizedBox(), activeSizeFactor: 1.5);
      final activeOptCopy = activeOpt.copyWith(activeSizeFactor: 2.0);
      expect(activeOptCopy.activeSizeFactor, 2.0);
      expect(activeOpt == activeOptCopy, isFalse);
      expect(activeOpt == activeOpt.copyWith(), isTrue);
      expect(activeOpt.hashCode, isNotNull);

      const gestOpt = GestureMarkerOptions();
      final gestOptCopy = gestOpt.copyWith(onTap: () {});
      expect(gestOptCopy.onTap, isNotNull);
      expect(gestOpt == gestOptCopy, isTrue);
      expect(gestOpt.hashCode, isNotNull);
    });
  });

  group('Overlay Options & Models', () {
    test('OverlayLayerOptions & OverlayHandleOptions copyWith and equality',
        () {
      const layerOpt = OverlayLayerOptions(alpha: 200);
      final layerOptCopy = layerOpt.copyWith(alpha: 255);
      expect(layerOptCopy.alpha, 255);
      expect(layerOpt == layerOptCopy, isFalse);
      expect(layerOpt == layerOpt.copyWith(), isTrue);
      expect(layerOpt.hashCode, isNotNull);

      const handleOpt = OverlayHandleOptions(size: 24, borderWidth: 3);
      final handleOptCopy = handleOpt.copyWith(size: 30);
      expect(handleOptCopy.size, 30);
      expect(handleOpt == handleOptCopy, isFalse);
      expect(handleOpt == handleOpt.copyWith(), isTrue);
      expect(handleOpt.hashCode, isNotNull);
    });

    test('Overlay Model Options copyWith and equality', () {
      const labelOpt = LabelOverlayOptions(label: SizedBox());
      final labelOptCopy = labelOpt.copyWith(rotate: false);
      expect(labelOptCopy.rotate, isFalse);
      expect(labelOpt == labelOptCopy, isFalse);
      expect(labelOpt == labelOpt.copyWith(), isTrue);
      expect(labelOpt.hashCode, isNotNull);

      const popupOpt =
          PopupOverlayOptions(popup: SizedBox(), alignment: Alignment.center);
      final popupOptCopy = popupOpt.copyWith(alignment: Alignment.topLeft);
      expect(popupOptCopy.alignment, Alignment.topLeft);
      expect(popupOpt == popupOptCopy, isFalse);
      expect(popupOpt == popupOpt.copyWith(), isTrue);
      expect(popupOpt.hashCode, isNotNull);

      const actionOpt = ActionOverlayOptions(action: SizedBox());
      final actionOptCopy = actionOpt.copyWith(alignment: Alignment.bottomLeft);
      expect(actionOptCopy.alignment, Alignment.bottomLeft);
      expect(actionOpt == actionOptCopy, isFalse);
      expect(actionOpt == actionOpt.copyWith(), isTrue);
      expect(actionOpt.hashCode, isNotNull);

      const activeOpt = ActiveOverlayOptions(outlineColor: Colors.blue);
      final activeOptCopy = activeOpt.copyWith(outlineColor: Colors.red);
      expect(activeOptCopy.outlineColor, Colors.red);
      expect(activeOpt == activeOptCopy, isFalse);
      expect(activeOpt == activeOpt.copyWith(), isTrue);
      expect(activeOpt.hashCode, isNotNull);

      const gestOpt = GestureOverlayOptions();
      final gestOptCopy = gestOpt.copyWith(onTap: () {});
      expect(gestOptCopy.onTap, isNotNull);
      expect(gestOpt == gestOptCopy, isTrue);
      expect(gestOpt.hashCode, isNotNull);
    });
  });

  group('Polyline Options & Models', () {
    test('PolylineLayerOptions & PolylineHandleOptions copyWith and equality',
        () {
      const layerOpt = PolylineLayerOptions(debug: true);
      final layerOptCopy = layerOpt.copyWith(debug: false);
      expect(layerOptCopy.debug, isFalse);
      expect(layerOpt == layerOptCopy, isFalse);
      expect(layerOpt == layerOpt.copyWith(), isTrue);
      expect(layerOpt.hashCode, isNotNull);

      const handleOpt = PolylineHandleOptions(size: 16);
      final handleOptCopy = handleOpt.copyWith(size: 20);
      expect(handleOptCopy.size, 20);
      expect(handleOpt == handleOptCopy, isFalse);
      expect(handleOpt == handleOpt.copyWith(), isTrue);
      expect(handleOpt.hashCode, isNotNull);
    });

    test('Polyline Model Options copyWith and equality', () {
      const labelOpt = LabelPolylineOptions();
      final labelOptCopy = labelOpt.copyWith(rotate: false);
      expect(labelOptCopy.rotate, isFalse);
      expect(labelOpt == labelOptCopy, isFalse);
      expect(labelOpt == labelOpt.copyWith(), isTrue);
      expect(labelOpt.hashCode, isNotNull);

      const popupOpt = PopupPolylineOptions(alignment: Alignment.center);
      final popupOptCopy = popupOpt.copyWith(alignment: Alignment.topRight);
      expect(popupOptCopy.alignment, Alignment.topRight);
      expect(popupOpt == popupOptCopy, isFalse);
      expect(popupOpt == popupOpt.copyWith(), isTrue);
      expect(popupOpt.hashCode, isNotNull);

      const actionOpt = ActionPolylineOptions(alignment: Alignment.centerLeft);
      final actionOptCopy =
          actionOpt.copyWith(alignment: Alignment.bottomRight);
      expect(actionOptCopy.alignment, Alignment.bottomRight);
      expect(actionOpt == actionOptCopy, isFalse);
      expect(actionOpt == actionOpt.copyWith(), isTrue);
      expect(actionOpt.hashCode, isNotNull);

      const activeOpt = ActivePolylineOptions(color: Colors.amber);
      final activeOptCopy = activeOpt.copyWith(color: Colors.purple);
      expect(activeOptCopy.color, Colors.purple);
      expect(activeOpt == activeOptCopy, isFalse);
      expect(activeOpt == activeOpt.copyWith(), isTrue);
      expect(activeOpt.hashCode, isNotNull);

      const gestOpt = GesturePolylineOptions();
      final gestOptCopy = gestOpt.copyWith(onTap: () {});
      expect(gestOptCopy.onTap, isNotNull);
      expect(gestOpt == gestOptCopy, isTrue);
      expect(gestOpt.hashCode, isNotNull);
    });
  });

  group('Label and Action Layers rendering', () {
    testWidgets('InteractiveMarkerLayer renders labels and action layers',
        (tester) async {
      final controller = MarkerController();
      final marker = InteractiveMarker(
        key: const ValueKey('m_full'),
        point: const LatLng(0, 0),
        child: const Icon(Icons.location_on),
        options: const [
          LabelMarkerOptions(
            label: Text('Label text'),
          ),
          PopupMarkerOptions(
            popup: Text('Popup text'),
          ),
        ],
      );

      await tester.pumpWidget(
        wrapMap(
          children: [
            InteractiveMarkerLayer(
              markerController: controller,
              markers: [marker],
              labelOptions: const LabelLayerOptions(),
              actionOptions: ActionLayerOptions(
                builder: (context, c, m) => const Text('Action widget'),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Label text'), findsOneWidget);

      // Enter edit mode and long press to activate action layer
      controller.startEditMode();
      controller.longPress(marker);
      await tester.pumpAndSettle();
      expect(find.text('Action widget'), findsOneWidget);
    });
  });
}
