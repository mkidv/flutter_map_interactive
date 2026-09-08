// ignore_for_file: avoid_print

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/interactive_controller.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// Mock Logic
class MockItem {
  MockItem(this.key, this.point);
  final Key key;
  final LatLng point;
}

// Mock Op
class MockOp extends Op<MockItem> {
  @override
  Op<MockItem> apply(List<MockItem> current) => this;
  @override
  Op<MockItem> revert(List<MockItem> current) => this;
  @override
  bool canMerge(Op<MockItem> other) => false;
  @override
  Op<MockItem> merge(Op<MockItem> other) => this;
}

class MockLogic extends EntityLogic<MockItem> {
  MockLogic() : super();

  @override
  Key? getItemKey(MockItem item) => item.key;
  @override
  LatLngBounds getBounds(MockItem item) => LatLngBounds(item.point, item.point);
  @override
  bool hasSpatialChange(MockItem a, MockItem b) => a.point != b.point;
  @override
  Op<MockItem> createAddOp(MockItem item) => MockOp();
  @override
  Op<MockItem> createRemoveOp(Key key) => MockOp();
  @override
  Op<MockItem> createUpdateOp(MockItem oldItem, MockItem newItem,
          {int index = -1}) =>
      MockOp();
  @override
  void ensureHasKey(MockItem item) {}

  @override
  Op<MockItem>? createDragEndOp(MockItem item, LatLng start, LatLng end) =>
      null;
  @override
  void onDragUpdate(MockItem item, LatLng start, LatLng current) {}
  @override
  void onInteraction(MockItem item, InteractionType type) {}
  @override
  void updateIndex(SpatialIndex<MockItem> index, Op<MockItem> op,
      MockItem? Function(Key) getItem) {}
}

class TestController extends InteractiveController<MockItem> {
  TestController() {
    logic = MockLogic();
  }
}

void main() {
  test('Benchmark: 10k Items Performance', () {
    final controller = TestController();
    final items =
        List.generate(10000, (i) => MockItem(Key('item_$i'), LatLng(0, 0)));

    final stopwatch = Stopwatch()..start();

    // 1. Set Items (Full Index Rebuild)
    controller.setItems(items, resetHistory: true);
    print('SetItems(10k): ${stopwatch.elapsedMilliseconds}ms');
    stopwatch.reset();

    // 2. FindByKey (Optimized)
    for (int i = 0; i < 1000; i++) {
      controller.findByKey(Key('item_${i * 10}'));
    }
    print('FindByKey(1000x): ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(50),
        reason: 'Map lookup should be instant');
    stopwatch.reset();

    // 3. Ensure Index Fresh (Lazy)
    controller.ensureIndexFresh();
    print('EnsureIndexFresh (Clean): ${stopwatch.elapsedMilliseconds}ms');
    stopwatch.reset();

    // 4. Force Rebuild (Simulate change)
    controller.setItems([...items, MockItem(Key('new'), LatLng(1, 1))],
        resetHistory: false);
    stopwatch.reset();
    controller.ensureIndexFresh();
    print('RebuildIndex(10k+1): ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(1800),
        reason:
            'Rebuild should stay within a reasonable budget in CI under full suite load');
  });
}
