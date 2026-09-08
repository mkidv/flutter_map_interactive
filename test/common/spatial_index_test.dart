import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('SpatialIndex', () {
    late SpatialIndex<String> index;

    setUp(() {
      index = SpatialIndex<String>(cellSize: 1.0);
    });

    test('should add and retrieve items', () {
      final key = const ValueKey('item1');
      final bounds = LatLngBounds(const LatLng(0, 0), const LatLng(1, 1));

      index.add(key, 'Item 1', bounds);

      expect(index.length, 1);
      expect(index.contains(key), isTrue);

      final result = index.query(bounds).toList();
      expect(result, contains('Item 1'));
    });

    test('should remove items', () {
      final key = const ValueKey('item1');
      final bounds = LatLngBounds(const LatLng(0, 0), const LatLng(0.5, 0.5));

      index.add(key, 'Item 1', bounds);
      index.remove(key);

      expect(index.length, 0);
      expect(index.contains(key), isFalse);

      final result = index.query(bounds).toList();
      expect(result, isEmpty);
    });

    test('should query items in range', () {
      // Item A: (0,0) to (1,1)
      index.add(
        const ValueKey('A'),
        'A',
        LatLngBounds(const LatLng(0, 0), const LatLng(1, 1)),
      );

      // Item B: (10,10) to (11,11) - Far away
      index.add(
        const ValueKey('B'),
        'B',
        LatLngBounds(const LatLng(10, 10), const LatLng(11, 11)),
      );

      // Query near A
      final queryA =
          LatLngBounds(const LatLng(-0.5, -0.5), const LatLng(1.5, 1.5));
      final resultA = index.query(queryA).toList();
      expect(resultA, contains('A'));
      expect(resultA, isNot(contains('B')));

      // Query near B
      final queryB =
          LatLngBounds(const LatLng(9.5, 9.5), const LatLng(11.5, 11.5));
      final resultB = index.query(queryB).toList();
      expect(resultB, contains('B'));
      expect(resultB, isNot(contains('A')));
    });

    test('should handle overlapping items', () {
      final bounds = LatLngBounds(const LatLng(0, 0), const LatLng(1, 1));

      index.add(const ValueKey('A'), 'A', bounds);
      index.add(const ValueKey('B'), 'B', bounds);

      final result = index.query(bounds).toList();
      expect(result, hasLength(2));
      expect(result, containsAll(['A', 'B']));
    });

    test('should handle items spanning multiple cells', () {
      // Create index with small cells
      index = SpatialIndex<String>();

      // Item spanning from 0,0 to 0.5,0.5 (covers ~25 cells)
      final bounds = LatLngBounds(const LatLng(0, 0), const LatLng(0.5, 0.5));
      index.add(const ValueKey('Big'), 'Big', bounds);

      // Query specific sub-cell
      final query =
          LatLngBounds(const LatLng(0.2, 0.2), const LatLng(0.25, 0.25));
      final result = index.query(query).toList();

      expect(result, contains('Big'));
    });
  });
}
