import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class MarkerHitTester {
  MarkerHitTester(this.cam, this.options, {this.index});
  final MapCamera cam;
  final MarkerLayerOptions options;
  final SpatialIndex<Marker>? index;

  Marker? hit(
    List<Marker> markers,
    Offset offset, {
    Key? preferKey,
    bool Function(Key?)? isActiveKey,
  }) {
    if (markers.isEmpty) return null;

    // 1. Check preferred key
    if (preferKey != null) {
      final prefer = markers.findByKeyOrNull(preferKey);
      if (prefer != null &&
          prefer.inPixelsBounds(cam, offset,
              options: options, active: isActiveKey?.call(prefer.key))) {
        return prefer;
      }
    }

    // 2. Prepare candidates
    Set<Key>? candidateKeys;
    if (index != null) {
      const double margin = 120.0;
      final bounds = _createHitBounds(offset, margin);
      candidateKeys =
          index!.query(bounds).map((m) => m.key).whereType<Key>().toSet();

      if (candidateKeys.isEmpty) return null;
    }

    // 3. Iterate in Z-order (reversed)
    for (final m in markers.reversed) {
      if (candidateKeys != null && !candidateKeys.contains(m.key)) continue;

      if (m.inPixelsBounds(cam, offset,
          options: options, active: isActiveKey?.call(m.key))) {
        return m;
      }
    }

    return null;
  }

  LatLngBounds _createHitBounds(Offset center, double margin) {
    // Unproject to LatLng using screenOffsetToLatLng which handles rotation/crs
    final p1 = cam
        .screenOffsetToLatLng(Offset(center.dx - margin, center.dy - margin));
    final p2 = cam
        .screenOffsetToLatLng(Offset(center.dx + margin, center.dy + margin));
    return LatLngBounds(
      LatLng(p1.latitude.clamp(-90.0, 90.0), p1.longitude.clamp(-180.0, 180.0)),
      LatLng(p2.latitude.clamp(-90.0, 90.0), p2.longitude.clamp(-180.0, 180.0)),
    );
  }
}
