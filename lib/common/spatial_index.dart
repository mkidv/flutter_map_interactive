import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

/// A generic spatial index for fast 2D range queries on geographical coordinates.
///
/// Uses a spatial hashing technique to bin items into cells based on their [LatLngBounds].
/// This allows O(1) average time complexity for querying items in a specific area,
/// drastically optimizing hit testing and visibility checks for large datasets.
///
/// It works in "World Space" (LatLng), making it independent of zoom level and screen size.
class SpatialIndex<T> {
  SpatialIndex({this.cellSize = 0.1});

  /// The collection of all items currently in the index.
  final Map<Key, _SpatialItem<T>> _items = {};

  /// The hash grid mapping cell hashes to lists of item keys.
  final Map<int, List<Key>> _buckets = {};

  /// Cell size in degrees (latitude/longitude).
  /// A value of 0.1 corresponds roughly to 11km at the equator.
  /// Adjust based on the expected density and size of items.
  final double cellSize;

  /// Adds or updates an item in the index.
  void add(Key key, T item, LatLngBounds bounds) {
    // If it exists, remove it first (to clear old buckets)
    if (_items.containsKey(key)) {
      remove(key);
    }
    _addInternal(key, item, bounds);
  }

  /// Optimised update when old bounds are known (avoids internal lookup).
  void update(Key key, T item, LatLngBounds oldBounds, LatLngBounds newBounds) {
    _removeInternal(key, oldBounds);
    _addInternal(key, item, newBounds);
  }

  void _addInternal(Key key, T item, LatLngBounds bounds) {
    final entry = _SpatialItem(item, bounds);
    _items[key] = entry;

    for (final hash in _getHashes(bounds)) {
      (_buckets[hash] ??= []).add(key);
    }
  }

  /// Removes an item from the index.
  void remove(Key key) {
    final entry = _items[key];
    if (entry == null) return;
    _removeInternal(key, entry.bounds);
  }

  void _removeInternal(Key key, LatLngBounds bounds) {
    _items.remove(key);
    for (final hash in _getHashes(bounds)) {
      final bucket = _buckets[hash];
      if (bucket != null) {
        bucket.remove(key);
        if (bucket.isEmpty) {
          _buckets.remove(hash);
        }
      }
    }
  }

  /// Clears the entire index.
  void clear() {
    _items.clear();
    _buckets.clear();
  }

  /// Returns all items whose bounds overlap with the given [queryBounds].
  ///
  /// This is a "broad phase" check. It returns potential matches.
  /// Precise geometry checks (like point-in-polygon) should be done on the results.
  Iterable<T> query(LatLngBounds queryBounds) sync* {
    final visited = <Key>{};

    for (final hash in _getHashes(queryBounds)) {
      final bucket = _buckets[hash];
      if (bucket == null) continue;

      for (final key in bucket) {
        if (visited.add(key)) {
          final entry = _items[key]!;
          // Precise bounds overlap check
          if (entry.bounds.isOverlapping(queryBounds)) {
            yield entry.item;
          }
        }
      }
    }
  }

  /// Generates cell hashes for the given bounds.
  Iterable<int> _getHashes(LatLngBounds bounds) sync* {
    final minLat = (bounds.south / cellSize).floor();
    final maxLat = (bounds.north / cellSize).floor();
    final minLng = (bounds.west / cellSize).floor();
    final maxLng = (bounds.east / cellSize).floor();

    for (var lat = minLat; lat <= maxLat; lat++) {
      for (var lng = minLng; lng <= maxLng; lng++) {
        yield _hash(lat, lng);
      }
    }
  }

  /// Simple spatial hashing function.
  int _hash(int lat, int lng) {
    // Cantor pairing or simple shift?
    // Using a simple bit shift strategy for reasonable integer ranges.
    // Lng (x) usually -180..180, Lat (y) -90..90.
    // With cellSize 0.1, indices are roughly -1800..1800.
    // 16 bits should be enough for each coordinate (range +/- 32767).
    return (lat & 0xFFFF) << 16 | (lng & 0xFFFF);
  }

  /// Returns true if the index contains the given key.
  bool contains(Key key) => _items.containsKey(key);

  /// Returns the number of items in the index.
  int get length => _items.length;
}

class _SpatialItem<T> {
  const _SpatialItem(this.item, this.bounds);
  final T item;
  final LatLngBounds bounds;
}
