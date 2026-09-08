import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_map_interactive/markers/controllers/op.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarkerLogic implements EntityLogic<Marker> {
  const MarkerLogic(this.editOptionsGetter);
  final InteractiveOptions<Marker> Function() editOptionsGetter;

  InteractiveOptions<Marker> get editOptions => editOptionsGetter();

  @override
  Key? getItemKey(Marker item) => item.key;

  @override
  void ensureHasKey(Marker item) => item.ensureHasKey();

  @override
  Op<Marker> createAddOp(Marker item) => AddMarkerOp(marker: item);

  @override
  Op<Marker> createRemoveOp(Key key) => RemoveMarkerOp(key: key);

  @override
  Op<Marker> createUpdateOp(Marker oldItem, Marker newItem, {int index = -1}) =>
      UpdateMarkerOp(oldMarker: oldItem, newMarker: newItem, index: index);

  @override
  bool hasSpatialChange(Marker oldItem, Marker newItem) {
    if (oldItem.point != newItem.point) return true;
    if (oldItem.width != newItem.width) return true;
    if (oldItem.height != newItem.height) return true;
    return false;
  }

  @override
  Op<Marker>? createDragEndOp(Marker item, LatLng origin, LatLng current) {
    final key = item.key;
    if (key == null) return null;
    return MoveMarkerOp(key: key, from: origin, to: current);
  }

  @override
  void onInteraction(Marker item, InteractionType type) {
    if (item is InteractiveMarker) {
      switch (type) {
        case InteractionType.tap:
          item.gestureOptions?.onTap?.call();
          break;
        case InteractionType.hover:
          item.gestureOptions?.onHover?.call();
          break;
        case InteractionType.longPress:
          item.gestureOptions?.onLongPress?.call();
          break;
        case InteractionType.active:
          item.gestureOptions?.onActive?.call();
          break;
      }
    }
  }

  @override
  void onDragUpdate(Marker item, LatLng origin, LatLng current) {
    // Logic from MarkerController._emitDragDebounced
    if (item is InteractiveMarker) {
      item.gestureOptions?.onPositionChanged?.call(origin, current);
    }
    // New generic spatial update call
    // Note: This isn't exactly mapping 1:1 to onMarkerPositionChanged(item, origin, current)
    // because generic onSpatialUpdate takes (newEntity, oldEntity).
    // But drag update is transient.
    // The previous onMarkerPositionChanged was: void Function(Marker marker, LatLng oldPoint, LatLng newPoint)? onMarkerPositionChanged;
    // The new one is onSpatialUpdate(T entity, T oldEntity).
    // We cannot construct T oldEntity easily here with just points.
    // However, onDragUpdate is primarily for FEEDBACK during drag, not necessarily committed change.
    // If the user relied on onMarkerPositionChanged for live feedback of the marker point,
    // they might need to inspect the transient state instead or we fire the callback with fabricated entities?
    // BUT, onSpatialUpdate is usually for committed changes or explicit moves?
    // Actually, check options.dart:
    // OnSpatialUpdateCallback<T> = void Function(T entity, T oldEntity);
    // Be careful relying on it for high-frequency drag updates if constructing entities is expensive.

    // For now, we will leave this empty or if critical, we'd need to fetch old entity state from controller/history?
    // But Logic class doesn't have access to controller state.

    // The previous code: editOptions.onMarkerPositionChanged?.call(item, origin, current);
    // 'item' here is the marker being dragged (the transient one potentially or the source one?).
    // Usually source one passed to onDragUpdate.
  }

  @override
  LatLngBounds getBounds(Marker item) {
    // Markers are point-based. We index the exact point.
    // The hit tester will need to query a region large enough to cover the max marker size.
    return LatLngBounds(item.point, item.point);
  }

  @override
  void updateIndex(SpatialIndex<Marker> index, Op<Marker> op,
      Marker? Function(Key) getItem) {
    switch (op) {
      case AddMarkerOp(:final marker):
        index.add(marker.key!, marker, getBounds(marker));
      case RemoveMarkerOp(:final key):
        index.remove(key);
      case MoveMarkerOp(:final key):
        final item = getItem(key);
        if (item != null) index.add(key, item, getBounds(item));
      case UpdateMarkerOp(:final newMarker):
        index.add(newMarker.key!, newMarker, getBounds(newMarker));
    }
  }
}
