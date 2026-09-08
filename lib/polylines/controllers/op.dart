import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:latlong2/latlong.dart';

/// Sealed class for polyline operations (undo/redo support).
sealed class PolylineOp implements Op<InteractivePolyline> {
  const PolylineOp();

  String get debugName;
}

/// Operation to add a polyline.
final class AddPolylineOp extends PolylineOp {
  const AddPolylineOp({required this.polyline});
  final InteractivePolyline polyline;

  @override
  String get debugName => 'Add(${polyline.key})';

  @override
  PolylineOp apply(List<InteractivePolyline> list) {
    list.add(polyline);
    return this;
  }

  @override
  PolylineOp revert(List<InteractivePolyline> list) {
    list.removeWhere((p) => p.key == polyline.key);
    return this;
  }

  @override
  bool canMerge(Op<InteractivePolyline> next) => false;

  @override
  PolylineOp merge(Op<InteractivePolyline> next) => this;
}

/// Operation to remove a polyline.
final class RemovePolylineOp extends PolylineOp {
  const RemovePolylineOp({
    required this.key,
    this.index = -1,
    this.removed,
  });
  final Key key;
  final int index;
  final InteractivePolyline? removed;

  RemovePolylineOp copyWith(
      {Key? key, int? index, InteractivePolyline? removed}) {
    return RemovePolylineOp(
      key: key ?? this.key,
      index: index ?? this.index,
      removed: removed ?? this.removed,
    );
  }

  @override
  String get debugName => 'Remove($key @ $index)';

  @override
  PolylineOp apply(List<InteractivePolyline> list) {
    final idx = list.indexWhere((p) => p.key == key);
    if (idx < 0) return this;
    final removedItem = list.removeAt(idx);
    return copyWith(index: idx, removed: removedItem);
  }

  @override
  PolylineOp revert(List<InteractivePolyline> list) {
    if (removed != null && index >= 0) {
      final idx = index.clamp(0, list.length);
      list.insert(idx, removed!);
    }
    return this;
  }

  @override
  bool canMerge(Op<InteractivePolyline> next) => false;

  @override
  PolylineOp merge(Op<InteractivePolyline> next) => this;
}

/// Operation to update a polyline.
final class UpdatePolylineOp extends PolylineOp {
  const UpdatePolylineOp({
    required this.oldPolyline,
    required this.newPolyline,
  });
  final InteractivePolyline oldPolyline;
  final InteractivePolyline newPolyline;

  @override
  String get debugName => 'Update(${newPolyline.key})';

  @override
  PolylineOp apply(List<InteractivePolyline> list) {
    final idx = list.indexWhere((p) => p.key == oldPolyline.key);
    if (idx >= 0) {
      list[idx] = newPolyline;
    }
    return this;
  }

  @override
  PolylineOp revert(List<InteractivePolyline> list) {
    final idx = list.indexWhere((p) => p.key == newPolyline.key);
    if (idx >= 0) {
      list[idx] = oldPolyline;
    }
    return this;
  }

  @override
  bool canMerge(Op<InteractivePolyline> next) => false;

  @override
  PolylineOp merge(Op<InteractivePolyline> next) => this;
}

/// Operation to move a single point of a polyline.
final class MovePointPolylineOp extends PolylineOp {
  const MovePointPolylineOp({
    required this.key,
    required this.index,
    required this.from,
    required this.to,
  });
  final Key key;
  final int index;
  final LatLng from;
  final LatLng to;

  @override
  String get debugName => 'MovePoint($key @ $index)';

  @override
  PolylineOp apply(List<InteractivePolyline> list) {
    final idx = list.indexWhere((p) => p.key == key);
    if (idx >= 0) {
      final target = list[idx];
      final newPoints = List<LatLng>.from(target.points);
      if (index >= 0 && index < newPoints.length) {
        newPoints[index] = to;
        list[idx] = target.copyWith(points: newPoints);
      }
    }
    return this;
  }

  @override
  PolylineOp revert(List<InteractivePolyline> list) {
    final idx = list.indexWhere((p) => p.key == key);
    if (idx >= 0) {
      final target = list[idx];
      final newPoints = List<LatLng>.from(target.points);
      if (index >= 0 && index < newPoints.length) {
        newPoints[index] = from;
        list[idx] = target.copyWith(points: newPoints);
      }
    }
    return this;
  }

  @override
  bool canMerge(Op<InteractivePolyline> next) =>
      next is MovePointPolylineOp && next.key == key && next.index == index;

  @override
  PolylineOp merge(Op<InteractivePolyline> next) {
    if (next is MovePointPolylineOp) {
      return MovePointPolylineOp(
          key: key, index: index, from: from, to: next.to);
    }
    return this;
  }
}

/// Operation to move an entire polyline.
final class MovePolylineOp extends PolylineOp {
  const MovePolylineOp({
    required this.key,
    required this.from,
    required this.to,
  });
  final Key key;
  final LatLng from;
  final LatLng to;

  @override
  String get debugName => 'Move($key)';

  @override
  PolylineOp apply(List<InteractivePolyline> list) {
    final idx = list.indexWhere((p) => p.key == key);
    if (idx >= 0) {
      final target = list[idx];
      final deltaLat = to.latitude - from.latitude;
      final deltaLng = to.longitude - from.longitude;
      final newPoints = target.points.map((p) {
        return LatLng(p.latitude + deltaLat, p.longitude + deltaLng);
      }).toList();
      list[idx] = target.copyWith(points: newPoints);
    }
    return this;
  }

  @override
  PolylineOp revert(List<InteractivePolyline> list) {
    final idx = list.indexWhere((p) => p.key == key);
    if (idx >= 0) {
      final target = list[idx];
      final deltaLat = from.latitude - to.latitude;
      final deltaLng = from.longitude - to.longitude;
      final newPoints = target.points.map((p) {
        return LatLng(p.latitude + deltaLat, p.longitude + deltaLng);
      }).toList();
      list[idx] = target.copyWith(points: newPoints);
    }
    return this;
  }

  @override
  bool canMerge(Op<InteractivePolyline> next) =>
      next is MovePolylineOp && next.key == key;

  @override
  PolylineOp merge(Op<InteractivePolyline> next) {
    if (next is MovePolylineOp) {
      return MovePolylineOp(key: key, from: from, to: next.to);
    }
    return this;
  }
}
