import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/layers/marker_layer.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';

class MarkerTransientLayer extends StatelessWidget {
  const MarkerTransientLayer({
    super.key,
    required this.controller,
    required this.options,
  });
  final MarkerController controller;
  final MarkerLayerOptions options;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.transientState,
      builder: (context, state, _) {
        if (state == null) return const SizedBox.shrink();

        // Create a temporary list with the single dragged marker at its new position
        final draggedMarker = InteractiveMarker.fromMarker(state.item).copyWith(
          point: state.current,
        );

        // We use InteractiveMarkerItemLayer to render it to ensure consistent styling/alignment
        return InteractiveMarkerItemLayer(
          markers: [draggedMarker],
          options: options,
        );
      },
    );
  }
}
