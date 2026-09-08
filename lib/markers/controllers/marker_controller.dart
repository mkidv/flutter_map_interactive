import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:flutter_map_interactive/common/interactive_controller.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/markers/controllers/op.dart';
import 'package:flutter_map_interactive/markers/interactive_marker_scope.dart';
import 'package:flutter_map_interactive/markers/logic/marker_logic.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A unified controller for managing marker state and interactions.
///
/// Uses [MarkerLogic] strategy for implementation details.
class MarkerController extends InteractiveController<Marker> {
  MarkerController() : super() {
    logic = MarkerLogic(() => _options);
  }

  static MarkerController? maybeOf(BuildContext context) =>
      InteractiveMarkerScope.maybeControllerOf(context);

  static MarkerController of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MarkerController.of()` should not be called outside a `InteractiveMarkerScope` or without a provider.'));

  // ===========================================================================
  // OPTIONS
  // ===========================================================================

  InteractiveOptions<Marker> _options = const InteractiveOptions();

  @override
  InteractiveOptions<Marker> get options => _options;

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  @override
  void setOptions(InteractiveOptions<Marker> options) {
    _options = options;
    super.setOptions(options);
  }

  // ===========================================================================
  // SPECIALIZED METHODS (Not covered by generic CRUD)
  // ===========================================================================

  void move(Key key, LatLng to, {bool merge = false}) {
    final before = findByKey(key);
    if (before == null) {
      debugPrint(
          'Warning: Attempted to move non-existent marker with key: $key');
      return;
    }
    perform(MoveMarkerOp(key: key, from: before.point, to: to), merge: merge);

    final after = findByKey(key);
    if (after != null) {
      _options.onSpatialUpdate?.call(after, before);
    }
    scheduleAutoSave();
  }

  void setMarkers(
    List<Marker> markers, {
    bool resetHistory = false,
    bool merge = false,
  }) {
    assert(() {
      for (final m in markers) {
        m.ensureHasKey();
      }
      return true;
    }());
    assert(
      !(resetHistory && merge),
      'setMarkers cannot reset history and merge at the same time.',
    );
    if (resetHistory) {
      setItems(markers, resetHistory: true);
      return;
    }

    if (merge) {
      final currentByKey = {
        for (final marker in current)
          if (marker.key != null) marker.key!: marker,
      };

      final merged = [
        for (final marker in markers)
          if (marker.key case final key?)
            switch (currentByKey[key]) {
              final Marker currentMarker? => _mergeMarker(currentMarker, marker),
              _ => marker,
            }
          else
            marker,
      ];

      setItems(merged, resetHistory: false);
      return;
    }

    setItems(markers, resetHistory: false);
  }

  Marker _mergeMarker(Marker current, Marker incoming) {
    final currentInteractive = InteractiveMarker.fromMarker(current);
    final incomingInteractive = InteractiveMarker.fromMarker(incoming);

    return incomingInteractive.copyWith(
      hidden: currentInteractive.isHidden,
    );
  }
}
