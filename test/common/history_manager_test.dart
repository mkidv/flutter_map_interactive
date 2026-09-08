import 'package:flutter_map_interactive/common/history/history_manager.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_test/flutter_test.dart';

class TestOp extends Op<int> {
  TestOp(this.addValue, {this.mergeable = false});
  final int addValue;
  final bool mergeable;

  @override
  Op<int> apply(List<int> items) {
    for (var i = 0; i < items.length; i++) {
      items[i] += addValue;
    }
    return this;
  }

  @override
  bool canMerge(Op<int> other) {
    return mergeable && other is TestOp && other.mergeable;
  }

  @override
  Op<int> merge(Op<int> other) {
    if (other is TestOp) {
      return TestOp(addValue + other.addValue, mergeable: true);
    }
    return other;
  }

  @override
  Op<int> revert(List<int> items) {
    for (var i = 0; i < items.length; i++) {
      items[i] -= addValue;
    }
    return this;
  }
}

void main() {
  group('HistoryManager', () {
    late HistoryManager<int> manager;

    setUp(() {
      manager = HistoryManager<int>();
      manager.setItems([0, 0], resetHistory: true);
    });

    test('initial state', () {
      expect(manager.current, [0, 0]);
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.version, isPositive);
    });

    test('commit updates current and requests rebuild', () {
      manager.commit(TestOp(1));
      expect(manager.current, [1, 1]);
      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
    });

    test('undo/redo works', () {
      manager.commit(TestOp(1)); // current: [1,1]
      manager.commit(TestOp(2)); // current: [3,3]

      expect(manager.current, [3, 3]);

      manager.undo();
      expect(manager.current, [1, 1]);

      manager.undo();
      expect(manager.current, [0, 0]);
      expect(manager.canUndo, isFalse);

      manager.redo();
      expect(manager.current, [1, 1]);

      manager.redo();
      expect(manager.current, [3, 3]);
      expect(manager.canRedo, isFalse);
    });

    test('save updates saved state', () {
      manager.commit(TestOp(5));
      manager.save();

      expect(manager.readOnlySaved, [5, 5]);
      // History should not be cleared by save unless erase=true (default false)
      expect(manager.canUndo, isTrue);
    });

    test('discard reverts to initial', () {
      manager.commit(TestOp(5));
      manager.discard();

      expect(manager.current, [0, 0]);
      expect(manager.canUndo, isFalse);
    });

    test('abort reverts to initial', () {
      manager.commit(TestOp(5));
      manager.commit(TestOp(3));
      manager.abort();

      expect(manager.current, [0, 0]);
      expect(manager.canUndo, isFalse);
      expect(manager.history, isEmpty);
    });

    test('merges operations within delay', () {
      manager.setMergeDelay(const Duration(milliseconds: 100));
      int time = 0;
      manager.testNowMs = () => time;

      // First op
      time = 0;
      manager.commit(TestOp(1, mergeable: true), merge: true);
      expect(manager.current, [1, 1]);
      expect(manager.history, hasLength(1));

      // Second op, within merge window
      time = 50;
      manager.commit(TestOp(2, mergeable: true), merge: true);
      expect(manager.current, [3, 3]); // 1 + 2 = 3
      expect(manager.history, hasLength(1)); // Still 1 op
      expect((manager.history.last as TestOp).addValue, 3); // Merged Op value

      // Third op, outside merge window
      time = 200;
      manager.commit(TestOp(1, mergeable: true), merge: true);
      expect(manager.current, [4, 4]);
      expect(manager.history, hasLength(2));
    });
  });
}
