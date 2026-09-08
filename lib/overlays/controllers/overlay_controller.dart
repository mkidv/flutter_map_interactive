import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/interactive_controller.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/overlays/controllers/op.dart';
import 'package:flutter_map_interactive/overlays/interactive_overlay_scope.dart';
import 'package:flutter_map_interactive/overlays/logic/overlay_logic.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:latlong2/latlong.dart';

class OverlayController extends InteractiveController<InteractiveOverlayImage> {
  OverlayController() : super() {
    logic = OverlayLogic(() => _options);
  }

  static OverlayController? maybeOf(BuildContext context) =>
      InteractiveOverlayScope.maybeControllerOf(context);
  static OverlayController of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
        '`OverlayController.of()` should not be called outside a provider/scope.',
      ));

  // ===========================================================================
  // OPTIONS
  // ===========================================================================

  InteractiveOptions<InteractiveOverlayImage> _options =
      const InteractiveOptions();

  @override
  InteractiveOptions<InteractiveOverlayImage> get options => _options;

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  @override
  void setOptions(InteractiveOptions<InteractiveOverlayImage> options) {
    _options = options;
    super.setOptions(options);
  }

  // ===========================================================================
  // METHODS (Specifics)
  // ===========================================================================

  void move(Key key, LatLng to, {bool merge = false}) {
    final before = findByKey(key);
    if (before == null) {
      debugPrint(
          'Warning: Attempted to move non-existent overlay with key: $key');
      return;
    }

    final centerBefore = before.center;
    final deltaLat = to.latitude - centerBefore.latitude;
    final deltaLng = to.longitude - centerBefore.longitude;

    final moved = before.copyWith(
      corners: before.corners.translate(deltaLat, deltaLng),
    );

    perform(
      UpdateOverlayOp(oldOverlay: before, newOverlay: moved),
      merge: merge,
    );

    _options.onSpatialUpdate?.call(moved, before);
    scheduleAutoSave();
  }

  void moveCorner(Key key, QuadCorner corner, LatLng to, {bool merge = false}) {
    final before = findByKey(key);
    if (before == null) {
      debugPrint(
          'Warning: Attempted to move corner of non-existent overlay with key: $key');
      return;
    }

    final from = before.corners.pointAt(corner);

    perform(
      MoveCornerOverlayOp(key: key, corner: corner, from: from, to: to),
      merge: merge,
    );

    // Debounced feedback can be added here if needed,
    // or via logic.onDragUpdate if we generalize corner drag.
    _options.onSpatialUpdate?.call(
      findByKey(key)!,
      before,
    );
    scheduleAutoSave();
  }

  void rotate(Key key, double angleRad, {bool merge = true}) {
    final old = findByKey(key);
    if (old == null) {
      debugPrint(
          'Warning: Attempted to rotate non-existent overlay with key: $key');
      return;
    }

    final center = old.center;
    final newOverlay = old.copyWith(
      corners: old.corners.rotate(angleRad, anchor: center),
    );

    perform(
      UpdateOverlayOp(oldOverlay: old, newOverlay: newOverlay),
      merge: merge,
    );
    _options.onSpatialUpdate?.call(newOverlay, old);
    scheduleAutoSave();
  }

  void setOverlays(List<InteractiveOverlayImage> overlays,
      {required bool resetHistory}) {
    setItems(overlays, resetHistory: resetHistory);
  }
}
