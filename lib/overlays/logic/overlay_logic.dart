import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';
import 'package:flutter_map_interactive/overlays/controllers/op.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:latlong2/latlong.dart';

class OverlayLogic implements EntityLogic<InteractiveOverlayImage> {
  const OverlayLogic(this.editOptionsGetter);
  final InteractiveOptions<InteractiveOverlayImage> Function()
      editOptionsGetter;

  InteractiveOptions<InteractiveOverlayImage> get editOptions =>
      editOptionsGetter();

  @override
  Key? getItemKey(InteractiveOverlayImage item) => item.key;

  @override
  void ensureHasKey(InteractiveOverlayImage item) {
    // InteractiveOverlayImage usually guarantees a key at construction time,
    // but if we had a setter it would be here.
    // It's a data class so we can't mutate it to add a key if missing.
    // Assuming valid input for now or throwing.
    if (item.key == null) throw ArgumentError('Overlay must have a key');
  }

  @override
  Op<InteractiveOverlayImage> createAddOp(InteractiveOverlayImage item) =>
      AddOverlayOp(overlay: item);

  @override
  Op<InteractiveOverlayImage> createRemoveOp(Key key) =>
      RemoveOverlayOp(key: key);

  @override
  Op<InteractiveOverlayImage> createUpdateOp(
          InteractiveOverlayImage oldItem, InteractiveOverlayImage newItem,
          {int index = -1}) =>
      UpdateOverlayOp(oldOverlay: oldItem, newOverlay: newItem);

  @override
  bool hasSpatialChange(
      InteractiveOverlayImage oldItem, InteractiveOverlayImage newItem) {
    return oldItem.corners != newItem.corners;
  }

  @override
  Op<InteractiveOverlayImage>? createDragEndOp(
      InteractiveOverlayImage item, LatLng origin, LatLng current) {
    final key = item.key;
    if (key == null) return null;

    final deltaLat = current.latitude - origin.latitude;
    final deltaLng = current.longitude - origin.longitude;

    // Calculate new geometry based on delta
    final moved = item.copyWith(
      corners: item.corners.translate(deltaLat, deltaLng),
    );

    return UpdateOverlayOp(oldOverlay: item, newOverlay: moved);
  }

  @override
  void onInteraction(InteractiveOverlayImage item, InteractionType type) {
    // No internal callbacks on the model itself for Overlays currently
  }

  @override
  void onDragUpdate(
      InteractiveOverlayImage item, LatLng origin, LatLng current) {
    // Overlay drag feedback is usually visual via the transient state layer,
    // but if we had a callback options.onDragUpdate it would go here.
  }
  @override
  LatLngBounds getBounds(InteractiveOverlayImage item) {
    return item.corners.bounds;
  }

  @override
  void updateIndex(
    SpatialIndex<InteractiveOverlayImage> index,
    Op<InteractiveOverlayImage> op,
    InteractiveOverlayImage? Function(Key) getItem,
  ) {
    switch (op) {
      case AddOverlayOp(:final overlay):
        index.add(overlay.key!, overlay, getBounds(overlay));
      case RemoveOverlayOp(:final key):
        index.remove(key);
      case UpdateOverlayOp(:final newOverlay):
        index.add(newOverlay.key!, newOverlay, getBounds(newOverlay));
      case MoveCornerOverlayOp(:final key):
        final item = getItem(key);
        if (item != null) index.add(key, item, getBounds(item));
    }
  }
}
