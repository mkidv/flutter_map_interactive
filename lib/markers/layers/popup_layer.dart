import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/widgets/containers.dart';

class PopupLayer extends StatelessWidget {
  const PopupLayer({
    super.key,
    required this.markers,
    required this.options,
  });
  final List<Marker> markers;
  final PopupLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = MarkerController.of(context);

    return Stack(
      children: [
        for (final marker in markers)
          if (marker.inMapBounds(cam,
              options: options, active: controller.isActiveKey(marker.key)))
            _PopupItem(
              key: marker.key,
              marker: InteractiveMarker.fromMarker(marker),
              options: options,
            ),
      ],
    );
  }
}

class _PopupItem extends StatelessWidget {
  const _PopupItem({super.key, required this.marker, required this.options});
  final InteractiveMarker marker;
  final PopupLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = MarkerController.of(context);
    return ListenableSelector(
      listenable: controller,
      select: (i) => i.isActiveKey(marker.key),
      builder: (context, isActive) {
        final child = marker.popupOptions?.popup ??
            options.builder?.call(context, controller, marker);

        if (child == null) {
          return const SizedBox.shrink();
        }

        final inactiveChild = SizedBox.shrink();

        final alignment = marker.popupOptions?.alignment ?? options.alignment;
        final rotate = marker.popupOptions?.rotate ?? options.rotate;
        final animationDuration =
            marker.popupOptions?.animationDuration ?? options.animationDuration;
        final animationCurve =
            marker.popupOptions?.animationCurve ?? options.animationCurve;
        final margin = marker.popupOptions?.margin ??
            options.margin ??
            EdgeInsets.symmetric(
                vertical: marker.height + 10, horizontal: marker.width + 10);

        final mapChild = FlutterMapAnimatedContainer(
          key: ValueKey('${marker.key}_popup'),
          camera: cam,
          point: marker.point,
          alignment: alignment * -1,
          rotate: rotate,
          animationDuration: animationDuration,
          animationCurve: animationCurve,
          animationBuilder: (context, anim, child) {
            final from = isActive ? 0.0 : 1.0;
            final to = isActive ? 1.0 : 0.0;
            final tween = Tween(begin: from, end: to);
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: anim.drive(tween),
                alignment: alignment * -1,
                child: child,
              ),
            );
          },
          margin: margin,
          child: KeyedSubtree(
            key: ValueKey(isActive
                ? '${marker.key}_popup_sel'
                : '${marker.key}_popup_unsel'),
            child: isActive ? child : inactiveChild,
          ),
        );

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
