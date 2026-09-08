import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/common/interactive_layer_state.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/interactive_overlay_scope.dart';
import 'package:flutter_map_interactive/overlays/layers/gesture_overlay_layer.dart';
import 'package:flutter_map_interactive/overlays/layers/options.dart';
import 'package:flutter_map_interactive/overlays/layers/overlay_handle_layer.dart';
import 'package:flutter_map_interactive/overlays/layers/overlay_layer.dart';
import 'package:flutter_map_interactive/overlays/layers/overlay_transient_layer.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';

class InteractiveOverlayLayer extends StatefulWidget {
  const InteractiveOverlayLayer({
    super.key,
    required this.overlays,
    this.overlayController,
    this.options = const OverlayLayerOptions(),
    this.interactiveOptions = const InteractiveOptions(),
    this.handleOptions = const OverlayHandleOptions(),
  });

  final List<InteractiveOverlayImage> overlays;
  final OverlayController? overlayController;
  final OverlayLayerOptions options;
  final InteractiveOptions<InteractiveOverlayImage> interactiveOptions;
  final OverlayHandleOptions handleOptions;

  @override
  State<InteractiveOverlayLayer> createState() =>
      _InteractiveOverlayLayerState();
}

class _InteractiveOverlayLayerState
    extends InteractiveLayerState<InteractiveOverlayLayer, OverlayController> {
  @override
  OverlayController? get widgetController => widget.overlayController;

  @override
  OverlayController createDefaultController() => OverlayController();

  @override
  void onInitController(OverlayController controller) {
    controller.setOverlays(widget.overlays, resetHistory: true);
    controller.setOptions(widget.interactiveOptions);
  }

  @override
  void onUpdateController(OverlayController controller) {
    controller.setOptions(widget.interactiveOptions);
  }

  @override
  void didUpdateWidget(covariant InteractiveOverlayLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged =
        oldWidget.overlayController != widget.overlayController;

    if (controllerChanged) {
      disposeControllersIfNeeded();
      initControllers();
    } else {
      onUpdateController(controller);
      final listChanged = !identical(oldWidget.overlays, widget.overlays);
      if (listChanged) {
        controller.setOverlays(widget.overlays, resetHistory: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveOverlayScope(
      controller: controller,
      builder: (context, overlays) {
        // Filter out hidden overlays
        final displayOverlays = controller.transientKeys.isEmpty
            ? overlays
            : overlays
                .where((o) => !controller.transientKeys.contains(o.key))
                .toList();

        return Stack(
          children: [
            OverlayLayer(overlays: displayOverlays, options: widget.options),
            OverlayTransientLayer(
              controller: controller,
              options: widget.options,
            ),
            OverlayGestureLayer(overlays: overlays),
            if (controller.isEditing)
              OverlayHandleLayer(
                overlays: overlays,
                options: widget.handleOptions,
              ),
          ],
        );
      },
    );
  }
}
