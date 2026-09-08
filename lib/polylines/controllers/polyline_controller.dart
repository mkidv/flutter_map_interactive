import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter_map_interactive/common/interactive_controller.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/polylines/controllers/op.dart';
import 'package:flutter_map_interactive/polylines/logic/polyline_logic.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:latlong2/latlong.dart';

/// A unified controller for managing polyline state (CRUD) and user interactions (Selection, Hover).
class PolylineController extends InteractiveController<InteractivePolyline> {
  PolylineController() : super() {
    logic = PolylineLogic(() => _options);
  }

  // ===========================================================================
  // OPTIONS
  // ===========================================================================

  InteractiveOptions<InteractivePolyline> _options = const InteractiveOptions();

  @override
  InteractiveOptions<InteractivePolyline> get options => _options;

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  @override
  void setOptions(InteractiveOptions<InteractivePolyline> options) {
    _options = options;
    super.setOptions(options);
  }

  // ===========================================================================
  // METHODS (EDIT)
  // ===========================================================================

  // Standard add/remove are handled by InteractiveController.
  // We can keep specific methods if they add value or validation.

  // Specific method to update points (since that's the main editable property)
  void updatePoints(Key key, List<LatLng> newPoints, {bool merge = false}) {
    final old = findByKey(key);
    if (old == null) {
      debugPrint(
          'Warning: Attempted to update points of non-existent polyline with key: $key');
      return;
    }

    final newPolyline = old.copyWith(points: List.of(newPoints));
    update(key, newPolyline, merge: merge);

    _options.onSpatialUpdate?.call(newPolyline, old);
  }

  void movePoint({
    required Key key,
    required int index,
    required LatLng from,
    required LatLng to,
    bool merge = false,
  }) {
    final p = findByKey(key);
    if (p == null) {
      debugPrint(
          'Warning: Attempted to move point of non-existent polyline with key: $key');
      return;
    }

    perform(
      MovePointPolylineOp(key: key, index: index, from: from, to: to),
      merge: merge,
    );
    scheduleAutoSave();
    // Note: Generic `update` won't be called automatically unless we used `update`.
    // But `PolylineOp.movePoint` updates the list.
    // Ideally we should use standard update if possible, but movePoint is granular transaction.
  }

  void move(Key key, LatLng to, {bool merge = false}) {
    final before = findByKey(key);
    if (before == null) {
      debugPrint(
          'Warning: Attempted to move non-existent polyline with key: $key');
      return;
    }

    if (before.points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(before.points);
    final centerBefore = bounds.center;

    perform(
      MovePolylineOp(key: key, from: centerBefore, to: to),
      merge: merge,
    );

    // Calculate new points for callback
    final deltaLat = to.latitude - centerBefore.latitude;
    final deltaLng = to.longitude - centerBefore.longitude;
    final newPoints = before.points.map((p) {
      return LatLng(p.latitude + deltaLat, p.longitude + deltaLng);
    }).toList();

    final moved = before.copyWith(points: newPoints);
    _options.onSpatialUpdate?.call(moved, before);
    scheduleAutoSave();
  }

  void setPolylines(List<InteractivePolyline> polylines,
      {required bool resetHistory}) {
    assert(() {
      for (final p in polylines) {
        if (p.key == null) throw ArgumentError('All polylines must have a key');
      }
      return true;
    }());
    setItems(polylines, resetHistory: resetHistory);
  }
}
