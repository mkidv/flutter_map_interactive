import 'dart:typed_data';

/// Spatial hash grid for fast collision queries.
/// Divides space into cells and tracks rectangles in each cell.
class SpatialHashGrid {
  SpatialHashGrid({this.cell = 32});
  final double cell;
  final Map<int, List<int>> _buckets = {};
  final _RectPool _pool = _RectPool();
  final Map<int, int> _cat = <int, int>{};

  int _h(int x, int y) => (x << 16) ^ (y & 0xFFFF);

  Iterable<(int, int)> _cellsFor(double l, double t, double r, double b) sync* {
    final x0 = (l / cell).floor(), y0 = (t / cell).floor();
    final x1 = (r / cell).floor(), y1 = (b / cell).floor();
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        yield (x, y);
      }
    }
  }

  void clear() {
    _buckets.clear();
    _pool.clear();
    _cat.clear();
  }

  int add(double l, double t, double r, double b, {required int category}) {
    final id = _pool.add(l, t, r, b);
    _cat[id] = category;
    for (final (x, y) in _cellsFor(l, t, r, b)) {
      final k = _h(x, y);
      (_buckets[k] ??= <int>[]).add(id);
    }
    return id;
  }

  bool collides(double l, double t, double r, double b, {int? mask}) {
    for (final (x, y) in _cellsFor(l, t, r, b)) {
      final list = _buckets[_h(x, y)];
      if (list == null) continue;
      for (final id in list) {
        if (mask != null && ((_cat[id]! & mask) == 0)) continue;
        if (_pool.overlaps(id, l, t, r, b)) return true;
      }
    }
    return false;
  }
}

/// Pool for storing Rect efficiently.
/// Used by _SpatialHashGrid for collision checks.
class _RectPool {
  Float32List _buf = Float32List(0);
  int _len = 0;
  final List<int> _free = <int>[];
  void clear() {
    _buf = Float32List(0);
    _len = 0;
    _free.clear();
  }

  int add(double l, double t, double r, double b) {
    final id = _free.isNotEmpty ? _free.removeLast() : _len++;
    _ensure(4 * _len);
    final o = id * 4;
    _buf[o] = l;
    _buf[o + 1] = t;
    _buf[o + 2] = r;
    _buf[o + 3] = b;
    return id;
  }

  bool overlaps(int id, double l, double t, double r, double b) {
    final o = id * 4;
    final l2 = _buf[o], t2 = _buf[o + 1], r2 = _buf[o + 2], b2 = _buf[o + 3];
    return !(r <= l2 || l >= r2 || b <= t2 || t >= b2);
  }

  void _ensure(int need) {
    if (_buf.length >= need) return;
    var n = _buf.isEmpty ? 64 : _buf.length;
    while (n < need) {
      n *= 2;
    }
    final next = Float32List(n)..setRange(0, _buf.length, _buf);
    _buf = next;
  }
}
