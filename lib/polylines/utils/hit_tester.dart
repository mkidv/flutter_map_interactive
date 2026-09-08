import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_map_interactive/utils/math.dart' as math_utils;
import 'package:latlong2/latlong.dart' hide Path;

class PolylineHitTester {
// ... (I should be careful not to replace the whole file if I can avoid it, but removing imports needs top of file)
// Actually, strict replace of garbage lines is safer.

// I will do 2 operations: remove garbage lines, then remove unused imports if I care.
// Lint said 'Unused import: dart:math' and 'latlong2/latlong.dart'.
// 'latlong2' IS used for LatLngBounds in _createHitBounds return type?
// Wait, _createHitBounds returns LatLngBounds.
// LatLngBounds is in 'package:latlong2/latlong.dart'.
// So the lint "Unused import: 'package:latlong2/latlong.dart'" might be wrong or satisfied by valid usage.
// Or maybe it's exported via flutter_map? No, flutter_map exports latlong2 usually.
// But explicit import is fine.

// Let's just fix the garbage code at the bottom first.
// Lines to remove: "    return bestHit;  }"

  PolylineHitTester(
    this.cam, {
    this.hitTolerance = 24.0,
    this.index,
  });

  final MapCamera cam;
  final double hitTolerance;
  final SpatialIndex<InteractivePolyline>? index;

  /// Returns the index of the hit polyline, or null.
  /// `preferKey` (active/hover) is tested first to feel "sticky" when overlapping.
  InteractivePolyline? hit(
    List<InteractivePolyline> polylines,
    Offset p, {
    Key? preferKey,
  }) {
    if (polylines.isEmpty) return null;

    // 1. Prepare candidates from Index
    Set<Key>? candidateKeys;
    if (index != null) {
      // Create a search bounds around the touch point based on tolerance
      final bounds = _createHitBounds(p, hitTolerance + 2.0); // +2 safety
      candidateKeys =
          index!.query(bounds).map((pl) => pl.key).whereType<Key>().toSet();

      if (candidateKeys.isEmpty) return null;
    }

    Iterable<int> order() sync* {
      if (preferKey != null) {
        final prefIdx = _indexOfKeyOrNull(polylines, preferKey);
        if (prefIdx != null) yield prefIdx;
      }
      for (int i = polylines.length - 1; i >= 0; i--) {
        if (preferKey != null && polylines[i].key == preferKey) continue;
        yield i; // top-most first
      }
    }

    double minDst = double.infinity;
    InteractivePolyline? bestHit;

    for (final i in order()) {
      final polyline = polylines[i];
      if (candidateKeys != null && !candidateKeys.contains(polyline.key)) {
        continue;
      }

      final points = polyline.points;

      // Optimization: Simple bbox check (redundant if using index, but cheap)
      // if (index == null && !polyline.bounds.contains(pointLatLng)) continue; // TODO: polyline.bounds?

      // Determine hit based on segments
      final offsets = points.map(cam.latLngToScreenOffset).toList();

      for (int j = 0; j < offsets.length - 1; j++) {
        final d = math_utils.distToSegment(p, offsets[j], offsets[j + 1]);
        if (d < hitTolerance && d < minDst) {
          minDst = d;
          bestHit = polyline;

          // Optimization: If we are very close to the line, assume direct hit.
          if (d < 0.5) {
            return polyline;
          }
          if (preferKey != null && polyline.key == preferKey) {
            return polyline;
          }
        }
      }
    }

    return bestHit;
  }

  LatLngBounds _createHitBounds(Offset center, double tolerance) {
    final p1 = cam.screenOffsetToLatLng(
        Offset(center.dx - tolerance, center.dy - tolerance));
    final p2 = cam.screenOffsetToLatLng(
        Offset(center.dx + tolerance, center.dy + tolerance));
    return LatLngBounds(
      LatLng(p1.latitude.clamp(-90.0, 90.0), p1.longitude.clamp(-180.0, 180.0)),
      LatLng(p2.latitude.clamp(-90.0, 90.0), p2.longitude.clamp(-180.0, 180.0)),
    );
  }

  int? _indexOfKeyOrNull(List<InteractivePolyline> polylines, Key key) {
    for (int i = 0; i < polylines.length; i++) {
      if (polylines[i].key == key) return i;
    }
    return null;
  }
}
