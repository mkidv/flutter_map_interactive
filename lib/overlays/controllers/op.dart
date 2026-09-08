import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:latlong2/latlong.dart';

/// Sealed class for overlay operations (undo/redo support).
sealed class OverlayOp implements Op<InteractiveOverlayImage> {
  const OverlayOp();

  String get debugName;
}

/// Operation to add an overlay.
final class AddOverlayOp extends OverlayOp {
  const AddOverlayOp({required this.overlay});
  final InteractiveOverlayImage overlay;

  @override
  String get debugName => 'Add(${overlay.key})';

  @override
  OverlayOp apply(List<InteractiveOverlayImage> list) {
    list.add(overlay);
    return this;
  }

  @override
  OverlayOp revert(List<InteractiveOverlayImage> list) {
    list.removeAtKey(overlay.key);
    return this;
  }

  @override
  bool canMerge(Op<InteractiveOverlayImage> next) => false;

  @override
  OverlayOp merge(Op<InteractiveOverlayImage> next) => this;
}

/// Operation to remove an overlay.
final class RemoveOverlayOp extends OverlayOp {
  const RemoveOverlayOp({
    required this.key,
    this.index = -1,
    this.removed,
  });
  final Key key;
  final int index;
  final InteractiveOverlayImage? removed;

  RemoveOverlayOp copyWith(
      {Key? key, int? index, InteractiveOverlayImage? removed}) {
    return RemoveOverlayOp(
      key: key ?? this.key,
      index: index ?? this.index,
      removed: removed ?? this.removed,
    );
  }

  @override
  String get debugName => 'Remove($key @ $index)';

  @override
  OverlayOp apply(List<InteractiveOverlayImage> list) {
    final res = list.removeAtKey(key);
    if (!res.removed || res.overlay == null) return this;
    return copyWith(index: res.index, removed: res.overlay);
  }

  @override
  OverlayOp revert(List<InteractiveOverlayImage> list) {
    if (removed != null && index >= 0) {
      final idx = index.clamp(0, list.length);
      list.insert(idx, removed!);
    }
    return this;
  }

  @override
  bool canMerge(Op<InteractiveOverlayImage> next) => false;

  @override
  OverlayOp merge(Op<InteractiveOverlayImage> next) => this;
}

/// Update complet (comme MarkerOp.update)
final class UpdateOverlayOp extends OverlayOp {
  const UpdateOverlayOp({
    required this.oldOverlay,
    required this.newOverlay,
  });
  final InteractiveOverlayImage oldOverlay;
  final InteractiveOverlayImage newOverlay;

  @override
  String get debugName => 'Update(${newOverlay.key})';

  @override
  OverlayOp apply(List<InteractiveOverlayImage> list) {
    list.updateByKey(oldOverlay.key, newOverlay);
    return this;
  }

  @override
  OverlayOp revert(List<InteractiveOverlayImage> list) {
    list.updateByKey(newOverlay.key, oldOverlay);
    return this;
  }

  @override
  bool canMerge(Op<InteractiveOverlayImage> next) =>
      next is UpdateOverlayOp && next.newOverlay.key == newOverlay.key;

  @override
  OverlayOp merge(Op<InteractiveOverlayImage> next) {
    if (next is UpdateOverlayOp) {
      return UpdateOverlayOp(
          oldOverlay: oldOverlay, newOverlay: next.newOverlay);
    }
    return this;
  }
}

/// Déplacement d'un coin (mergeable)
final class MoveCornerOverlayOp extends OverlayOp {
  const MoveCornerOverlayOp({
    required this.key,
    required this.corner,
    required this.from,
    required this.to,
  });
  final Key key;
  final QuadCorner corner;
  final LatLng from;
  final LatLng to;

  @override
  String get debugName => 'MoveCorner($key:$corner '
      '(${from.latitude.toStringAsFixed(6)},${from.longitude.toStringAsFixed(6)})'
      ' -> (${to.latitude.toStringAsFixed(6)},${to.longitude.toStringAsFixed(6)}))';

  @override
  OverlayOp apply(List<InteractiveOverlayImage> list) {
    final old = list.findByKeyOrNull(key);
    if (old == null) return this;

    final next = _withCorner(old, corner, to);
    list.updateByKey(key, next);
    return this;
  }

  @override
  OverlayOp revert(List<InteractiveOverlayImage> list) {
    final old = list.findByKeyOrNull(key);
    if (old == null) return this;

    final prev = _withCorner(old, corner, from);
    list.updateByKey(key, prev);
    return this;
  }

  @override
  bool canMerge(Op<InteractiveOverlayImage> next) =>
      next is MoveCornerOverlayOp && next.key == key && next.corner == corner;

  @override
  OverlayOp merge(Op<InteractiveOverlayImage> next) {
    if (next is MoveCornerOverlayOp) {
      return MoveCornerOverlayOp(
          key: key, corner: corner, from: from, to: next.to);
    }
    return this;
  }
}

InteractiveOverlayImage _withCorner(
    InteractiveOverlayImage o, QuadCorner c, LatLng p) {
  return o.copyWith(corners: o.corners.copyWithCorner(c, p));
}
