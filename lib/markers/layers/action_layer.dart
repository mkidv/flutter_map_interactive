import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/widgets/containers.dart';

class ActionLayer extends StatelessWidget {
  const ActionLayer({
    super.key,
    required this.markers,
    required this.options,
  });
  final List<Marker> markers;
  final ActionLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = MarkerController.of(context);

    return Stack(
      children: [
        for (final marker in markers)
          if (marker.inMapBounds(cam,
              options: options, active: controller.isActiveKey(marker.key)))
            _ActionItem(
              key: marker.key,
              marker: InteractiveMarker.fromMarker(marker),
              options: options,
            ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({super.key, required this.marker, required this.options});
  final InteractiveMarker marker;
  final ActionLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = MarkerController.of(context);
    return ListenableSelector(
      listenable: controller,
      select: (i) => i.isLongPressedKey(marker.key),
      builder: (context, isLongPressed) {
        if (!isLongPressed) {
          return const SizedBox.shrink();
        }

        final child = marker.actionOptions?.action ??
            options.builder?.call(context, controller, marker);

        if (child == null) {
          return const SizedBox.shrink();
        }

        final alignment = marker.actionOptions?.alignment ?? options.alignment;
        final rotate = marker.actionOptions?.rotate ?? options.rotate;
        final animationDuration = marker.actionOptions?.animationDuration ??
            options.animationDuration;
        final animationCurve =
            marker.actionOptions?.animationCurve ?? options.animationCurve;
        final margin = marker.actionOptions?.margin ??
            options.margin ??
            EdgeInsets.symmetric(
                vertical: marker.height, horizontal: marker.width);

        final mapChild = FlutterMapAnimatedContainer(
            key: ValueKey('${marker.key}_action'),
            camera: cam,
            point: marker.point,
            alignment: alignment * -1,
            rotate: rotate,
            animationDuration: animationDuration,
            animationCurve: animationCurve,
            margin: margin,
            child: child);

        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              mapChild
            ],
          ),
        );
      },
    );
  }
}
