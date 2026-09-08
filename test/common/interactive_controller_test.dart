import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/events.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/interactive_controller.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// -- Mock Implementation --

class TestItem {
  const TestItem(this.id, this.value);
  final String id;
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value;

  @override
  int get hashCode => id.hashCode ^ value.hashCode;

  @override
  String toString() => 'TestItem($id, $value)';
}

class TestItemOp extends Op<TestItem> {
  TestItemOp.add(this.newItem)
      : isAdd = true,
        removeKey = null;
  TestItemOp.remove(this.removeKey)
      : isAdd = false,
        newItem = null;
  final TestItem? newItem;
  final Key? removeKey;
  final bool isAdd;

  @override
  Op<TestItem> apply(List<TestItem> current) {
    if (isAdd) {
      current.add(newItem!);
    } else {
      current.removeWhere((item) => ValueKey(item.id) == removeKey);
    }
    return this;
  }

  @override
  bool canMerge(Op<TestItem> other) => false;

  @override
  Op<TestItem> merge(Op<TestItem> other) => other;

  @override
  Op<TestItem> revert(List<TestItem> current) {
    if (isAdd) {
      current.remove(newItem!);
    } else {}
    return this;
  }
}

class TestUpdateValueOp extends Op<TestItem> {
  TestUpdateValueOp({
    required this.key,
    required this.from,
    required this.to,
  });

  final Key key;
  final int from;
  final int to;

  @override
  Op<TestItem> apply(List<TestItem> current) {
    final index = current.indexWhere((item) => ValueKey(item.id) == key);
    if (index != -1) {
      current[index] = TestItem((key as ValueKey<String>).value, to);
    }
    return this;
  }

  @override
  bool canMerge(Op<TestItem> other) =>
      other is TestUpdateValueOp && other.key == key;

  @override
  Op<TestItem> merge(Op<TestItem> other) {
    final next = other as TestUpdateValueOp;
    return TestUpdateValueOp(
      key: key,
      from: from,
      to: next.to,
    );
  }

  @override
  Op<TestItem> revert(List<TestItem> current) {
    final index = current.indexWhere((item) => ValueKey(item.id) == key);
    if (index != -1) {
      current[index] = TestItem((key as ValueKey<String>).value, from);
    }
    return this;
  }
}

class TestLogic implements EntityLogic<TestItem> {
  @override
  Key? getItemKey(TestItem item) => ValueKey(item.id);

  @override
  void ensureHasKey(TestItem item) {}

  @override
  Op<TestItem> createAddOp(TestItem item) => TestItemOp.add(item);

  @override
  Op<TestItem> createRemoveOp(Key key) => TestItemOp.remove(key);

  @override
  Op<TestItem> createUpdateOp(TestItem oldItem, TestItem newItem,
          {int index = -1}) =>
      TestUpdateValueOp(
        key: ValueKey(oldItem.id),
        from: oldItem.value,
        to: newItem.value,
      );

  @override
  bool hasSpatialChange(TestItem oldItem, TestItem newItem) => false;

  @override
  Op<TestItem>? createDragEndOp(TestItem item, LatLng origin, LatLng current) =>
      createUpdateOp(item, TestItem(item.id, item.value + 1));

  @override
  void onInteraction(TestItem item, InteractionType type) {}

  @override
  void onDragUpdate(TestItem item, LatLng origin, LatLng current) {}

  @override
  LatLngBounds getBounds(TestItem item) =>
      LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));

  @override
  void updateIndex(SpatialIndex<TestItem> index, Op<TestItem> op,
      TestItem? Function(Key) getItem) {
    if (op is TestItemOp) {
      if (op.isAdd) {
        index.add(
            getItemKey(op.newItem!)!, op.newItem!, getBounds(op.newItem!));
      }
    }
  }
}

class TestController extends InteractiveController<TestItem> {
  TestController() : super() {
    logic = TestLogic();
  }

  // Expose protected methods for testing
  void addItem(TestItem item) {
    add(item);
  }

  void removeItem(TestItem item) {
    remove(ValueKey(item.id));
  }

  @override
  void setEditModeCallback(ValueChanged<bool>? callback) {
    super.setEditModeCallback(callback);
  }
}

void main() {
  group('InteractiveController', () {
    late TestController controller;

    setUp(() {
      controller = TestController();
    });

    test('initial state', () {
      expect(controller.current, isEmpty);
      expect(controller.hasActive, isFalse);
      expect(controller.hasHovered, isFalse);
      expect(controller.isEditing, isFalse);
    });

    group('Interaction Management', () {
      final item1 = const TestItem('1', 10);
      final item2 = const TestItem('2', 20);

      setUp(() {
        controller.addItem(item1);
        controller.addItem(item2);
      });

      test('selection works', () {
        controller.select(item1);
        expect(controller.activeItem, item1);
        expect(controller.isActive(item1), isTrue);
        expect(controller.isActive(item2), isFalse);

        // Toggle invalidates selection if same
        controller.toggleSelect(item1);
        expect(controller.hasActive, isFalse);

        // Toggle selects if different
        controller.toggleSelect(item2);
        expect(controller.activeItem, item2);
      });

      test('hover triggers callback', () {
        fakeAsync((async) {
          controller.hover(item1);

          async.elapse(const Duration(milliseconds: 50));
          expect(controller.hasHovered, isTrue);
        });
      });

      test('interaction references are cleaned up on item removal', () {
        controller.select(item1);
        expect(controller.hasActive, isTrue);

        // Perform removal via Op (undoable)
        controller.removeItem(item1);

        expect(controller.current, isNot(contains(item1)));
        // The controller listens to history changes and refreshes interaction refs
        expect(controller.hasActive, isFalse);
      });
    });

    group('Edit Mode', () {
      test('toggles edit mode', () {
        bool changed = false;
        controller.setEditModeCallback((val) => changed = val);

        controller.startEditMode();
        expect(controller.isEditing, isTrue);
        expect(changed, isTrue);

        controller.exitEditMode();
        expect(controller.isEditing, isFalse);
        expect(changed, isFalse);
      });

      test('emits edit mode events', () async {
        final events = <InteractiveEvent<TestItem>>[];
        final sub = controller.events.listen(events.add);

        controller.startEditMode();
        controller.exitEditMode();
        await Future<void>.delayed(Duration.zero);

        expect(
            events
                .whereType<EditModeChanged<TestItem>>()
                .map((e) => e.isEditing),
            [true, false]);

        await sub.cancel();
      });

      test('saveOnExit persists pending changes before leaving edit mode', () {
        controller.setOptions(const InteractiveOptions<TestItem>());

        controller.addItem(const TestItem('1', 10));
        controller.save();
        controller.startEditMode();
        controller.addItem(const TestItem('2', 20));

        controller.exitEditMode();
        controller.discard();

        expect(
          controller.current,
          [
            const TestItem('1', 10),
            const TestItem('2', 20),
          ],
        );
      });

      test('saveOnExit disabled keeps pending changes discardable after exit',
          () {
        controller.setOptions(
          const InteractiveOptions<TestItem>(saveOnExit: false),
        );

        controller.addItem(const TestItem('1', 10));
        controller.save();
        controller.startEditMode();
        controller.addItem(const TestItem('2', 20));

        controller.exitEditMode();
        controller.discard();

        expect(controller.current, [const TestItem('1', 10)]);
      });
    });

    group('History Events', () {
      test('emits history events on add and undo', () async {
        final events = <InteractiveEvent<TestItem>>[];
        final sub = controller.events.listen(events.add);

        controller.addItem(const TestItem('1', 10));
        controller.undo();
        await Future<void>.delayed(Duration.zero);

        final historyEvents =
            events.whereType<HistoryChanged<TestItem>>().toList();
        expect(historyEvents, isNotEmpty);
        expect(historyEvents.first.current.length, 1);
        expect(historyEvents.last.current, isEmpty);

        await sub.cancel();
      });

      test('discard and abort refresh current state lookups', () {
        const item = TestItem('1', 10);
        const item2 = TestItem('2', 20);

        controller.addItem(item);
        controller.save();
        controller.addItem(item2);

        expect(controller.findByKey(const ValueKey('2')), item2);

        controller.discard();
        expect(controller.findByKey(const ValueKey('2')), isNull);
        expect(controller.findByKey(const ValueKey('1')), item);

        controller.abort();
        expect(controller.findByKey(const ValueKey('1')), isNull);
      });

      test('mergeDelay from options is propagated to history merging', () {
        controller.setOptions(
          const InteractiveOptions<TestItem>(
            mergeDelay: Duration(milliseconds: 10),
          ),
        );

        controller.addItem(const TestItem('1', 10));

        var now = 0;
        controller.history.testNowMs = () => now;

        controller.performOp(
          TestUpdateValueOp(key: const ValueKey('1'), from: 10, to: 11),
          merge: true,
        );

        now = 5;
        controller.performOp(
          TestUpdateValueOp(key: const ValueKey('1'), from: 11, to: 12),
          merge: true,
        );

        expect(controller.history.history.length, 2);
        expect(controller.current.last, const TestItem('1', 12));

        now = 25;
        controller.performOp(
          TestUpdateValueOp(key: const ValueKey('1'), from: 12, to: 13),
          merge: true,
        );

        expect(controller.history.history.length, 3);
        expect(controller.current.last, const TestItem('1', 13));
      });
    });

    group('Drag Events', () {
      test('emits drag lifecycle events in order', () async {
        const item = TestItem('1', 10);
        final events = <InteractiveEvent<TestItem>>[];
        final sub = controller.events.listen(events.add);

        controller.addItem(item);
        controller.startDrag(item, const LatLng(0, 0));
        controller.updateDrag(const LatLng(1, 1));
        controller.endDrag();
        await Future<void>.delayed(Duration.zero);

        expect(events.whereType<DragStarted<TestItem>>().length, 1);
        expect(events.whereType<DragUpdated<TestItem>>().length, 1);
        expect(events.whereType<DragEnded<TestItem>>().length, 1);
        expect(
          events
              .where((event) =>
                  event is DragStarted<TestItem> ||
                  event is DragUpdated<TestItem> ||
                  event is DragEnded<TestItem>)
              .map((event) => event.runtimeType),
          [
            DragStarted<TestItem>,
            DragUpdated<TestItem>,
            DragEnded<TestItem>,
          ],
        );

        await sub.cancel();
      });
    });
  });
}
