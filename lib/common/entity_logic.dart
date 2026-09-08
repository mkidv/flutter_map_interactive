import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:latlong2/latlong.dart';

enum InteractionType { tap, hover, longPress, active }

/// Encapsulates type-specific logic for [InteractiveController].
abstract class EntityLogic<T> {
  // ---/ Identity & Validation /---
  Key? getItemKey(T item);
  void ensureHasKey(T item);

  // ---/ Transactional Ops (The "Write" Model) /---
  Op<T> createAddOp(T item);
  Op<T> createRemoveOp(Key key);
  Op<T> createUpdateOp(T oldItem, T newItem, {int index = -1});

  // ---/ Diffing Support /---
  /// Returns true if the change between a and b is spatial (position/geometry).
  bool hasSpatialChange(T oldItem, T newItem);

  // ---/ Interaction Logic (The "Controller" logic) /---
  /// Convert a generic drag end into a concrete commit operation.
  Op<T>? createDragEndOp(T item, LatLng origin, LatLng current);

  /// Handle interaction side-effects (e.g., internal model callbacks).
  void onInteraction(T item, InteractionType type);

  /// Handle drag updates (e.g., debounced position change callbacks).
  void onDragUpdate(T item, LatLng origin, LatLng current);

  // ---/ Spatial Indexing /---
  /// Get the bounds of the item for spatial indexing.
  LatLngBounds getBounds(T item);

  /// Updates the spatial index based on the operation.
  /// [getItem] allows retrieving the current state of an item by key (useful for Move ops).
  void updateIndex(SpatialIndex<T> index, Op<T> op, T? Function(Key) getItem);
}
