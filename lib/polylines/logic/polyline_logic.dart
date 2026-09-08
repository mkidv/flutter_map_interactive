import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_map_interactive/polylines/controllers/op.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:latlong2/latlong.dart';

class PolylineLogic implements EntityLogic<InteractivePolyline> {
  const PolylineLogic(this.editOptionsGetter);
  final InteractiveOptions<InteractivePolyline> Function() editOptionsGetter;

  InteractiveOptions<InteractivePolyline> get editOptions =>
      editOptionsGetter();

  @override
  Key? getItemKey(InteractivePolyline item) => item.key;

  @override
  void ensureHasKey(InteractivePolyline item) {
    if (item.key == null) throw ArgumentError('Polyline must have a key');
  }

  @override
  Op<InteractivePolyline> createAddOp(InteractivePolyline item) =>
      AddPolylineOp(polyline: item);

  @override
  Op<InteractivePolyline> createRemoveOp(Key key) => RemovePolylineOp(key: key);

  @override
  Op<InteractivePolyline> createUpdateOp(
          InteractivePolyline oldItem, InteractivePolyline newItem,
          {int index = -1}) =>
      UpdatePolylineOp(oldPolyline: oldItem, newPolyline: newItem);

  @override
  bool hasSpatialChange(
      InteractivePolyline oldItem, InteractivePolyline newItem) {
    if (oldItem.points.length != newItem.points.length) return true;
    for (int i = 0; i < oldItem.points.length; i++) {
      if (oldItem.points[i] != newItem.points[i]) return true;
    }
    return false;
  }

  @override
  Op<InteractivePolyline>? createDragEndOp(
      InteractivePolyline item, LatLng origin, LatLng current) {
    final key = item.key;
    if (key == null) return null;

    final deltaLat = current.latitude - origin.latitude;
    final deltaLng = current.longitude - origin.longitude;

    final newPoints = item.points.map((p) {
      return LatLng(p.latitude + deltaLat, p.longitude + deltaLng);
    }).toList();

    final moved = item.copyWith(points: newPoints);

    return UpdatePolylineOp(oldPolyline: item, newPolyline: moved);
  }

  @override
  void onInteraction(InteractivePolyline item, InteractionType type) {
    // No internal callbacks on the model itself for Polylines currently
  }

  @override
  void onDragUpdate(InteractivePolyline item, LatLng origin, LatLng current) {
    // Polyline drag feedback
  }

  @override
  LatLngBounds getBounds(InteractivePolyline item) {
    if (item.points.isEmpty) {
      return LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));
    }
    return LatLngBounds.fromPoints(item.points);
  }

  @override
  void updateIndex(
    SpatialIndex<InteractivePolyline> index,
    Op<InteractivePolyline> op,
    InteractivePolyline? Function(Key) getItem,
  ) {
    switch (op) {
      case AddPolylineOp(:final polyline):
        index.add(polyline.key!, polyline, getBounds(polyline));
      case RemovePolylineOp(:final key):
        index.remove(key);
      case UpdatePolylineOp(:final newPolyline):
        index.add(newPolyline.key!, newPolyline, getBounds(newPolyline));
      case MovePolylineOp(:final key):
        final item = getItem(key);
        if (item != null) {
          index.add(key, item, getBounds(item));
        }
      case MovePointPolylineOp(:final key):
        final item = getItem(key);
        if (item != null) {
          index.add(key, item, getBounds(item));
        }
    }
  }
}
