import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/reactive/stream_listenable.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/widgets/containers.dart';

class LabelLayer extends StatelessWidget {
  const LabelLayer({
    super.key,
    required this.markers,
    required this.options,
  });
  final List<Marker> markers;
  final LabelLayerOptions options;

  @override
  Widget build(BuildContext context) {
    final map = MapController.of(context);
    final controller = MarkerController.of(context);

    if (options.hideOnEdit && controller.isEditing) {
      return const SizedBox.shrink();
    }

    final repaint = map.mapEventStream.asListenable();

    return CollisionLayoutBuilder<InteractiveMarker>(
      repaint: repaint,
      strategy: options.strategy,
      options: options.collision,
      buildNodes: (ctx, cam) {
        return markers
            .where(
                (m) => m.inMapBounds(cam, options: options, active: controller.isActiveKey(m.key)))
            .map((m) {
          final em = InteractiveMarker.fromMarker(m);

          final priority = controller.isActiveKey(em.key)
              ? 0
              : controller.isHoveredKey(em.key)
                  ? 1
                  : 10;

          final anchorRect = em.pixelBounds(cam, active: controller.isActiveKey(em.key));

          Widget buildLabel(BuildContext c) =>
              em.labelOptions?.label ??
              options.builder?.call(c, controller, em) ??
              const SizedBox.shrink();

          return CollisionNode<InteractiveMarker>(
            key: em.key!,
            anchor: em.point,
            alignment: em.labelOptions?.alignment ?? options.alignment,
            margin: em.labelOptions?.margin ??
                options.margin ??
                EdgeInsets.symmetric(vertical: em.height, horizontal: em.width),
            rotate: em.labelOptions?.rotate ?? options.rotate,
            priority: priority,
            anchorRectPx: anchorRect,
            measureBuilder: buildLabel,
            data: em,
          );
        }).toList();
      },
      builder: (ctx, cam, node, place) {
        final labelChild = node.measureBuilder?.call(ctx) ?? const SizedBox.shrink();

        return ListenableSelector(
            listenable: controller,
            select: (i) => i.isHoveredKey(node.data?.key),
            builder: (context, isHovered) => FlutterMapContainer(
                  key: ValueKey('${node.key}_label'),
                  camera: cam,
                  point: node.anchor,
                  alignment: node.alignment * -1,
                  rotate: node.rotate,
                  margin: node.margin,
                  pixelOffset: place.offsetPx,
                  glow: isHovered,
                  child: labelChild,
                ));
      },
    );
  }
}
