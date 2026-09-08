import 'package:flutter_map_interactive/common/transient_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('TransientState', () {
    const origin = LatLng(0, 0);
    const current = LatLng(5, 5);
    const testItem = 'test_item';

    test('constructor creates instance with all fields', () {
      final state = TransientState<String>(
        item: testItem,
        current: current,
        origin: origin,
      );

      expect(state.item, testItem);
      expect(state.current, current);
      expect(state.origin, origin);
    });

    test('copyWith preserves origin when updating current', () {
      final state = TransientState<String>(
        item: testItem,
        current: origin,
        origin: origin,
      );

      final updated = state.copyWith(current: current);

      expect(updated.origin, origin);
      expect(updated.current, current);
      expect(updated.item, testItem);
    });

    test('copyWith can update current position', () {
      final state = TransientState<String>(
        item: testItem,
        current: origin,
        origin: origin,
      );

      const newCurrent = LatLng(10, 10);
      final updated = state.copyWith(current: newCurrent);

      expect(updated.current, newCurrent);
      expect(updated.origin, origin);
    });

    test('equality checks work correctly', () {
      final state1 = TransientState<String>(
        item: testItem,
        current: current,
        origin: origin,
      );

      final state2 = TransientState<String>(
        item: testItem,
        current: current,
        origin: origin,
      );

      final state3 = TransientState<String>(
        item: 'different_item',
        current: current,
        origin: origin,
      );

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
      expect(state1, isNot(state3));
    });

    test('immutability - copyWith creates new instance', () {
      final state = TransientState<String>(
        item: testItem,
        current: origin,
        origin: origin,
      );

      final updated = state.copyWith(current: current);

      expect(identical(state, updated), isFalse);
      expect(state.current, origin);
      expect(updated.current, current);
    });

    test('works with different item types', () {
      final intState = TransientState<int>(
        item: 42,
        current: origin,
        origin: origin,
      );

      expect(intState.item, 42);

      final mapState = TransientState<Map<String, dynamic>>(
        item: {'key': 'value'},
        current: origin,
        origin: origin,
      );

      expect(mapState.item['key'], 'value');
    });

    test('current can be same as origin', () {
      final state = TransientState<String>(
        item: testItem,
        current: origin,
        origin: origin,
      );

      expect(state.current, state.origin);
    });

    test('supports complex item types', () {
      final complexItem = _TestComplexItem('id1', 100);

      final state = TransientState<_TestComplexItem>(
        item: complexItem,
        current: origin,
        origin: origin,
      );

      expect(state.item.id, 'id1');
      expect(state.item.value, 100);
    });
  });
}

class _TestComplexItem {
  _TestComplexItem(this.id, this.value);
  final String id;
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestComplexItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value;

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}
