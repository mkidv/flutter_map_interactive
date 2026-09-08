import 'package:flutter_map_interactive/common/entity_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityDelta.diff', () {
    test('detects added items', () {
      final oldList = [1, 2];
      final newList = [1, 2, 3];
      final result = EntityDelta<int>.diff(
        oldList,
        newList,
        keySelector: (i) => i,
        hasSpatialChange: (_, __) => false,
      );
      expect(result.added, [3]);
      expect(result.removed, isEmpty);
      expect(result.moved, isEmpty);
      expect(result.updated, isEmpty);
    });

    test('detects removed items', () {
      final oldList = [1, 2, 3];
      final newList = [1, 2];
      final result = EntityDelta<int>.diff(
        oldList,
        newList,
        keySelector: (i) => i,
        hasSpatialChange: (_, __) => false,
      );
      expect(result.added, isEmpty);
      expect(result.removed, [3]);
    });

    test('detects moved items based on predicate', () {
      final oldItem = _Item(id: 1, pos: 10);
      final newItemMoved = _Item(id: 1, pos: 20); // Moved

      final result = EntityDelta<_Item>.diff(
        [oldItem],
        [newItemMoved],
        keySelector: (i) => i.id,
        hasSpatialChange: (a, b) => a.pos != b.pos,
      );

      expect(result.moved, hasLength(1));
      expect(result.moved.first.$1, oldItem);
      expect(result.moved.first.$2, newItemMoved);
      expect(result.updated, isEmpty);
    });

    test('detects updated items (not moved)', () {
      final oldItem = _Item(id: 1, pos: 10, data: 'a');
      final newItemUpdated =
          _Item(id: 1, pos: 10, data: 'b'); // data changed, pos same

      final result = EntityDelta<_Item>.diff(
        [oldItem],
        [newItemUpdated],
        keySelector: (i) => i.id,
        hasSpatialChange: (a, b) => a.pos != b.pos,
      );

      expect(result.moved, isEmpty);
      expect(result.updated, hasLength(1));
      expect(result.updated.first.$1, oldItem);
      expect(result.updated.first.$2, newItemUpdated);
    });
  });
}

class _Item {
  _Item({required this.id, required this.pos, this.data = ''});
  final int id;
  final int pos;
  final String data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pos == other.pos &&
          data == other.data;

  @override
  int get hashCode => id.hashCode ^ pos.hashCode ^ data.hashCode;
}
