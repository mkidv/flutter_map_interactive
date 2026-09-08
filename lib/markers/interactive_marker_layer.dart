import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:flutter_map_interactive/common/interactive_layer_state.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/layers/marker_hitbox_layer.dart';
import 'package:flutter_map_interactive/layers/marker_target_layer.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/interactive_marker_scope.dart';
import 'package:flutter_map_interactive/markers/layers/action_layer.dart';
import 'package:flutter_map_interactive/markers/layers/gesture_layer.dart';
import 'package:flutter_map_interactive/markers/layers/label_layer.dart';
import 'package:flutter_map_interactive/markers/layers/marker_layer.dart';
import 'package:flutter_map_interactive/markers/layers/marker_transient_layer.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/layers/popup_layer.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';

/// A Map Layer that renders [Marker]s with enhanced capabilities.
///
/// Features include:
/// - **Collision Detection**: Hides markers that overlap/collide based on priority.
/// - **Editing**: Allows moving, adding, and deleting markers via [MarkerController].
/// - **Interaction**: Handles tap, long press, and hover events via [MarkerController].
/// - **Sub-layers**: Supports optional layers for popups, labels, and actions.
///
/// Use [InteractiveMarker] to unlock specific features per marker.
class InteractiveMarkerLayer extends StatefulWidget {
  const InteractiveMarkerLayer({
    super.key,
    required this.markers,
    this.markerController,
    this.options = const InteractiveOptions(),
    this.markerOptions =
        const MarkerLayerOptions(alignment: Alignment.bottomCenter),
    this.popupOptions,
    this.labelOptions,
    this.actionOptions,
    this.debug = false,
  });

  /// The list of markers to display.
  ///
  /// For advanced features, providing [InteractiveMarker] instances is recommended,
  /// but standard [Marker]s are also supported (treated with default options).
  final List<Marker> markers;

  /// Optional controller to manage markers and interactions externally.
  final MarkerController? markerController;

  /// Options for interactions and editing.
  final InteractiveOptions<Marker> options;

  /// Configuration for the underlying [MarkerLayer] rendered by flutter_map.
  final MarkerLayerOptions markerOptions;

  /// Configuration for the optional [PopupLayer].
  ///
  /// If provided, a popup layer will be rendered on top of markers.
  final PopupLayerOptions? popupOptions;

  /// Configuration for the optional [LabelLayer].
  ///
  /// If provided, labels defined in [LabelMarkerOptions] will be rendered.
  final LabelLayerOptions? labelOptions;

  /// Configuration for the optional [ActionLayer].
  ///
  /// If provided, action menus (e.g., delete button) will be shown when editing.
  final ActionLayerOptions? actionOptions;

  /// Whether to show debug information (e.g. hitboxes).
  final bool debug;

  @override
  State<InteractiveMarkerLayer> createState() => _InteractiveMarkerLayerState();
}

class _InteractiveMarkerLayerState
    extends InteractiveLayerState<InteractiveMarkerLayer, MarkerController> {
  List<Marker>? _pendingMarkersSync;
  bool _markersSyncScheduled = false;

  @override
  MarkerController? get widgetController => widget.markerController;

  @override
  MarkerController createDefaultController() => MarkerController();

  @override
  void onInitController(MarkerController controller) {
    controller.setOptions(widget.options);
    controller.setMarkers(widget.markers, resetHistory: true);
  }

  @override
  void onUpdateController(MarkerController controller) {
    controller.setOptions(widget.options);
  }

  void _scheduleMarkerSync(List<Marker> markers) {
    _pendingMarkersSync = markers;
    if (_markersSyncScheduled) return;

    _markersSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markersSyncScheduled = false;
      if (!mounted) return;

      final markersToSync = _pendingMarkersSync;
      _pendingMarkersSync = null;
      if (markersToSync == null) return;

      final shouldResetHistory = !controller.hasUnsavedChanges;
      controller.setMarkers(
        markersToSync,
        resetHistory: shouldResetHistory,
        merge: !shouldResetHistory,
      );
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged =
        oldWidget.markerController != widget.markerController;

    if (controllerChanged) {
      disposeControllersIfNeeded();
      initControllers();
    } else {
      onUpdateController(controller);

      // Check for content equality to avoid spurious updates
      final markersChanged = !identical(oldWidget.markers, widget.markers) &&
          !const DeepCollectionEquality()
              .equals(oldWidget.markers, widget.markers);

      if (markersChanged) {
        _scheduleMarkerSync(widget.markers);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveMarkerScope(
      controller: controller,
      builder: (context, markers) {
        final visibleMarkers = markers
            .where((marker) => !InteractiveMarker.fromMarker(marker).isHidden)
            .toList();
        final displayMarkers = controller.transientKeys.isEmpty
            ? visibleMarkers
            : visibleMarkers
                .where((m) => !controller.transientKeys.contains(m.key))
                .toList();

        return Stack(children: [
          if (widget.debug) ...[
            MarkerHitboxLayer(
              markers: displayMarkers,
              options: widget.markerOptions,
            ),
            MarkerTargetLayer(markers: displayMarkers)
          ],
          if (widget.labelOptions != null)
            LabelLayer(
              markers: displayMarkers,
              options: widget.labelOptions!,
            ),
          MarkerLayer(
            markers: displayMarkers,
            options: widget.markerOptions,
          ),
          MarkerTransientLayer(
            controller: controller,
            options: widget.markerOptions,
          ),
          GestureLayer(
            markers: visibleMarkers,
            options: widget.options,
            layerOptions: widget.markerOptions,
          ),
          if (widget.popupOptions != null && !controller.isEditing)
            PopupLayer(
              markers: displayMarkers,
              options: widget.popupOptions!,
            ),
          if (widget.actionOptions != null && controller.isEditing)
            ActionLayer(
              markers: displayMarkers,
              options: widget.actionOptions!,
            ),
        ]);
      },
    );
  }
}
