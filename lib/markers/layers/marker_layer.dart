import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/widgets/containers.dart';

class MarkerLayer extends StatelessWidget {
  const MarkerLayer({
    super.key,
    required this.markers,
    required this.options,
  });
  final List<Marker> markers;
  final MarkerLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = MarkerController.of(context);

    return Stack(
      children: [
        for (final marker in markers)
          if (marker.inMapBounds(cam,
              options: options, active: controller.isActiveKey(marker.key)))
            _MarkerItem(
              key: marker.key,
              marker: InteractiveMarker.fromMarker(marker),
              options: options,
            ),
      ],
    );
  }
}

class _MarkerItem extends StatelessWidget {
  const _MarkerItem({super.key, required this.marker, required this.options});
  final InteractiveMarker marker;
  final MarkerLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = MarkerController.of(context);
    return ListenableSelector(
        listenable: controller,
        select: (i) => (i.isActiveKey(marker.key), i.isHoveredKey(marker.key)),
        builder: (context, state) {
          final (isActive, isHovered) = state;
          final alignment = marker.alignment ?? options.alignment;
          final rotate = marker.rotate ?? options.rotate;

          final activeChild = (options is InteractiveLayerOptions)
              ? (marker.activeOptions?.active ??
                  (options as InteractiveLayerOptions)
                      .activeBuilder
                      ?.call(context, controller, marker) ??
                  marker.child)
              : marker.child;

          final inactiveChild = marker.child;

          return FlutterMapAnimatedContainer(
            key: ValueKey('${marker.key}_container'),
            camera: cam,
            point: marker.point,
            alignment: alignment,
            rotate: rotate,
            glow: isHovered,
            animateOnMount: false,
            restartOnPointChange: false,
            animationDuration: const Duration(milliseconds: 120),
            animationCurve: isActive ? Curves.easeInCubic : Curves.easeOutCubic,
            animationBuilder: (context, animation, child) {
              final selScale =
                  marker.resolveScale(options: options, active: isActive);
              final from = isActive ? 1.0 : selScale;
              final to = isActive ? selScale : 1.0;
              final tween = Tween(begin: from, end: to);
              return ScaleTransition(
                scale: animation.drive(tween),
                alignment: alignment,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey(
                  isActive ? '${marker.key}_sel' : '${marker.key}_unsel'),
              child: isActive ? activeChild : inactiveChild,
            ),
          );
        });
  }
}
