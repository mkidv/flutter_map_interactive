import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/layers/options.dart';
import 'package:flutter_map_interactive/overlays/layers/overlay_layer.dart';

class OverlayTransientLayer extends StatelessWidget {
  const OverlayTransientLayer({
    super.key,
    required this.controller,
    required this.options,
  });
  final OverlayController controller;
  final OverlayLayerOptions options;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.transientState,
      builder: (context, state, _) {
        if (state == null) return const SizedBox.shrink();

        final original = state.item;
        final startPos = state.origin;
        final currentPos = state.current;

        // Calculate delta
        final deltaLat = currentPos.latitude - startPos.latitude;
        final deltaLng = currentPos.longitude - startPos.longitude;

        // Create a temporary overlay moved by delta
        // We moved the corners
        final draggedOverlay = original.copyWith(
          corners: original.corners.translate(deltaLat, deltaLng),
        );

        return OverlayLayer(
          overlays: [draggedOverlay],
          options: options,
        );
      },
    );
  }
}
