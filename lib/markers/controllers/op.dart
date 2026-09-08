import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Sealed class for marker operations (undo/redo support).
sealed class MarkerOp implements Op<Marker> {
  const MarkerOp();

  String get debugName;
}

/// Operation to add a marker.
final class AddMarkerOp extends MarkerOp {
  const AddMarkerOp({required this.marker});
  final Marker marker;

  @override
  String get debugName => 'Add(${marker.key})';

  @override
  MarkerOp apply(List<Marker> list) {
    list.add(marker);
    return this;
  }

  @override
  MarkerOp revert(List<Marker> list) {
    list.removeAtKey(marker.key);
    return this;
  }

  @override
  bool canMerge(Op<Marker> next) => false;

  @override
  MarkerOp merge(Op<Marker> next) => this;
}

/// Operation to remove a marker.
final class RemoveMarkerOp extends MarkerOp {
  const RemoveMarkerOp({
    required this.key,
    this.index = -1,
    this.removed,
  });
  final Key key;
  final int index;
  final Marker? removed;

  RemoveMarkerOp copyWith({Key? key, int? index, Marker? removed}) {
    return RemoveMarkerOp(
      key: key ?? this.key,
      index: index ?? this.index,
      removed: removed ?? this.removed,
    );
  }

  @override
  String get debugName => 'Remove($key @ $index)';

  @override
  MarkerOp apply(List<Marker> list) {
    final res = list.removeAtKey(key);
    if (!res.removed || res.marker == null) return this;
    return copyWith(index: res.index, removed: res.marker);
  }

  @override
  MarkerOp revert(List<Marker> list) {
    if (removed != null && index >= 0) {
      final idx = index.clamp(0, list.length);
      list.insert(idx, removed!);
    }
    return this;
  }

  @override
  bool canMerge(Op<Marker> next) => false;

  @override
  MarkerOp merge(Op<Marker> next) => this;
}

/// Operation to move a marker to a new position.
final class MoveMarkerOp extends MarkerOp {
  const MoveMarkerOp({
    required this.key,
    required this.from,
    required this.to,
  });
  final Key key;
  final LatLng from;
  final LatLng to;

  @override
  String get debugName =>
      'Move($key: (${from.latitude.toStringAsFixed(6)},${from.longitude.toStringAsFixed(6)})'
      ' -> (${to.latitude.toStringAsFixed(6)},${to.longitude.toStringAsFixed(6)}))';

  @override
  MarkerOp apply(List<Marker> list) {
    list.updatePointByKey(key, to);
    return this;
  }

  @override
  MarkerOp revert(List<Marker> list) {
    list.updatePointByKey(key, from);
    return this;
  }

  @override
  bool canMerge(Op<Marker> next) => next is MoveMarkerOp && next.key == key;

  @override
  MarkerOp merge(Op<Marker> next) {
    if (next is MoveMarkerOp) {
      return MoveMarkerOp(key: key, from: from, to: next.to);
    }
    return this;
  }
}

/// Operation to update a marker.
final class UpdateMarkerOp extends MarkerOp {
  const UpdateMarkerOp({
    required this.oldMarker,
    required this.newMarker,
    this.index = -1,
  });
  final Marker oldMarker;
  final Marker newMarker;
  final int index;

  @override
  String get debugName => 'Update(${newMarker.key})';

  @override
  MarkerOp apply(List<Marker> list) {
    if (index >= 0 && index < list.length && list[index].key == oldMarker.key) {
      list[index] = newMarker;
    } else {
      list.updateByKey(oldMarker.key, newMarker); // Fallback
    }
    return this;
  }

  @override
  MarkerOp revert(List<Marker> list) {
    list.updateByKey(newMarker.key, oldMarker);
    return this;
  }

  @override
  bool canMerge(Op<Marker> next) => false;

  @override
  MarkerOp merge(Op<Marker> next) => this;
}
