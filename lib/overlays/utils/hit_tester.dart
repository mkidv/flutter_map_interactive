import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_map_interactive/utils/math.dart' as math_utils;
import 'package:latlong2/latlong.dart';

class OverlayHitTester {
  OverlayHitTester(
    this.cam, {
    this.quadPaddingPx = 6.0,
    this.index,
  });

  final MapCamera cam;
  final double quadPaddingPx;
  final SpatialIndex<InteractiveOverlayImage>? index;

  /// Returns the index of the hit overlay, or null.
  /// `preferKey` (active/hover) is tested first to feel "sticky" when overlapping.
  InteractiveOverlayImage? hit(
    List<InteractiveOverlayImage> overlays,
    Offset p, {
    Key? preferKey,
  }) {
    if (overlays.isEmpty) return null;

    // Pre-calculate latlng of the screen point for broad phase check
    final rawPoint = cam.screenOffsetToLatLng(p);
    final pointLatLng = LatLng(
      rawPoint.latitude.clamp(-90.0, 90.0),
      rawPoint.longitude.clamp(-180.0, 180.0),
    );

    // Candidates from index
    Set<Key>? candidateKeys;
    if (index != null) {
      // Query the point directly.
      candidateKeys = index!
          .query(LatLngBounds(pointLatLng, pointLatLng))
          .map((o) => o.key)
          .whereType<Key>()
          .toSet();

      if (candidateKeys.isEmpty) return null;
    }

    Iterable<int> order() sync* {
      if (preferKey != null) {
        final prefIdx = _indexOfKeyOrNull(overlays, preferKey);
        if (prefIdx != null) yield prefIdx;
      }
      for (int i = overlays.length - 1; i >= 0; i--) {
        if (preferKey != null && overlays[i].key == preferKey) continue;
        yield i; // top-most first
      }
    }

    for (final i in order()) {
      final o = overlays[i];

      if (candidateKeys != null && !candidateKeys.contains(o.key)) continue;

      // Broad phase: Check if point is roughly within the bounds of the overlay
      // This avoids 4 expensive screen projections for every overlay.
      // If index is used, this is redundant but harmless.
      if (index == null && !o.corners.bounds.contains(pointLatLng)) continue;

      final tl = cam.latLngToScreenOffset(o.corners.topLeft);
      final tr = cam.latLngToScreenOffset(o.corners.topRight);
      final br = cam.latLngToScreenOffset(o.corners.bottomRight);
      final bl = cam.latLngToScreenOffset(o.corners.bottomLeft);

      if (!_inPaddedBounds(p, tl, tr, br, bl, quadPaddingPx)) continue;
      if (math_utils.pointInQuad4(p, tl, tr, br, bl)) return o;
    }

    return null;
  }

  @pragma('vm:prefer-inline')
  int? _indexOfKeyOrNull(List<InteractiveOverlayImage> overlays, Key key) {
    for (int i = 0; i < overlays.length; i++) {
      if (overlays[i].key == key) return i;
    }
    return null;
  }

  @pragma('vm:prefer-inline')
  bool _inPaddedBounds(
      Offset p, Offset tl, Offset tr, Offset br, Offset bl, double pad) {
    final minX = _min4(tl.dx, tr.dx, br.dx, bl.dx) - pad;
    final maxX = _max4(tl.dx, tr.dx, br.dx, bl.dx) + pad;
    final minY = _min4(tl.dy, tr.dy, br.dy, bl.dy) - pad;
    final maxY = _max4(tl.dy, tr.dy, br.dy, bl.dy) + pad;
    return !(p.dx < minX || p.dx > maxX || p.dy < minY || p.dy > maxY);
  }

  @pragma('vm:prefer-inline')
  double _min4(double a, double b, double c, double d) {
    var m = a;
    if (b < m) m = b;
    if (c < m) m = c;
    if (d < m) m = d;
    return m;
  }

  @pragma('vm:prefer-inline')
  double _max4(double a, double b, double c, double d) {
    var m = a;
    if (b > m) m = b;
    if (c > m) m = c;
    if (d > m) m = d;
    return m;
  }
}
