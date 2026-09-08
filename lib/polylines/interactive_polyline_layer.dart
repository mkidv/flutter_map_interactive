import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'
    hide MarkerLayer, InteractionOptions;
import 'package:flutter_map_interactive/common/interactive_layer_state.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/layers/polyline_hitbox_layer.dart';
import 'package:flutter_map_interactive/polylines/controllers/polyline_controller.dart';
import 'package:flutter_map_interactive/polylines/interactive_polyline_scope.dart';
import 'package:flutter_map_interactive/polylines/layers/gesture_polyline_layer.dart';
import 'package:flutter_map_interactive/polylines/layers/options.dart';
import 'package:flutter_map_interactive/polylines/layers/polyline_handle_layer.dart';
import 'package:flutter_map_interactive/polylines/layers/polyline_transient_layer.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';

class InteractivePolylineLayer extends StatefulWidget {
  const InteractivePolylineLayer({
    super.key,
    required this.polylines,
    this.polylineController,
    this.options = const InteractiveOptions(),
    this.handleOptions = const PolylineHandleOptions(),
    this.debug = false,
  });

  /// The list of polylines to display.
  final List<InteractivePolyline> polylines;

  /// Controller to manage polylines (add, remove, update, selection).
  final PolylineController? polylineController;

  /// Options for interactions and editing.
  final InteractiveOptions<InteractivePolyline> options;

  final PolylineHandleOptions handleOptions;

  final bool debug;

  @override
  State<InteractivePolylineLayer> createState() =>
      _InteractivePolylineLayerState();
}

class _InteractivePolylineLayerState extends InteractiveLayerState<
    InteractivePolylineLayer, PolylineController> {
  @override
  PolylineController? get widgetController => widget.polylineController;

  @override
  PolylineController createDefaultController() => PolylineController();

  @override
  void onInitController(PolylineController controller) {
    controller.setOptions(widget.options);
    controller.setPolylines(widget.polylines, resetHistory: true);
  }

  @override
  void onUpdateController(PolylineController controller) {
    controller.setOptions(widget.options);
  }

  @override
  void didUpdateWidget(covariant InteractivePolylineLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged =
        oldWidget.polylineController != widget.polylineController;

    if (controllerChanged) {
      disposeControllersIfNeeded();
      initControllers();
    } else {
      onUpdateController(controller);
      if (oldWidget.polylines != widget.polylines) {
        controller.setPolylines(widget.polylines, resetHistory: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractivePolylineScope(
      controller: controller,
      builder: (context, polylines) {
        // Filter out hidden polylines
        final displayPolylines = controller.transientKeys.isEmpty
            ? polylines
            : polylines
                .where((p) => !controller.transientKeys.contains(p.key))
                .toList();

        return Stack(
          children: [
            if (widget.debug) ...[
              PolylineHitboxLayer(
                polylines: displayPolylines,
              ),
            ],
            PolylineLayer(polylines: displayPolylines),
            PolylineTransientLayer(controller: controller),
            PolylineGestureLayer(polylines: polylines),
            if (controller.isEditing)
              PolylineHandleLayer(
                polylines: polylines,
                options: widget.handleOptions,
              ),
          ],
        );
      },
    );
  }
}
