import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show MapCamera, MapController;
import 'package:flutter_map_interactive/polylines/controllers/polyline_controller.dart';
import 'package:flutter_map_interactive/polylines/interactive_polyline_scope.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_map_interactive/polylines/utils/hit_tester.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/utils/hit_test_gesture_detector.dart';
import 'package:flutter_map_interactive/utils/rect_ops.dart';
import 'package:latlong2/latlong.dart';

class PolylineGestureLayer extends StatefulWidget {
  const PolylineGestureLayer({
    super.key,
    required this.polylines,
    this.hitTolerance = 24.0,
  });

  final List<InteractivePolyline> polylines;
  final double hitTolerance;

  @override
  State<PolylineGestureLayer> createState() => _PolylineGestureLayerState();
}

class _PolylineGestureLayerState extends State<PolylineGestureLayer>
    with TickerProviderStateMixin {
  late MapCamera cam;
  late PolylineController controller;
  late MapController map;
  late List<InteractivePolyline> polylines;

  @override
  Widget build(BuildContext context) {
    cam = MapCamera.of(context);
    controller = InteractivePolylineScope.controllerOf(context);
    map = MapController.of(context);
    polylines = widget.polylines;

    return ListenableSelector(
      listenable: controller,
      select: (i) => i.isEditing,
      builder: (context, isEditing) {
        final options = controller.options;
        final gestures = options.enabledGestures;

        final canTap = gestures.tap;
        final canHover = gestures.hover;
        final canDrag = isEditing && gestures.drag;
        final canLongPress = isEditing && gestures.longPress;

        return HitTestableGestureDetector<InteractivePolyline>(
          behavior: HitTestBehavior.translucent,
          hitTest: _hitOffset,
          onHover: canHover ? _onHover : null,
          onTapUp: canTap ? _onTapUp : null,
          onSecondaryTapUp: canLongPress ? _onSecondaryTapUp : null,
          onLongPressStart:
              canLongPress ? (d, o) => _onDragStart(d.localPosition, o) : null,
          onLongPressMoveUpdate:
              canLongPress ? (d, _) => _onDragUpdate(d.localPosition) : null,
          onLongPressEnd:
              canLongPress ? (d, o) => _onDragEnd(d.localPosition, o) : null,
          onPanStart:
              canDrag ? (d, o) => _onDragStart(d.localPosition, o) : null,
          onPanUpdate:
              canDrag ? (d, _) => _onDragUpdate(d.localPosition) : null,
          onPanEnd: canDrag ? (d, o) => _onDragEnd(d.localPosition, o) : null,
        );
      },
    );
  }

  InteractivePolyline? _hitOffset(Offset offset) {
    // Ensure spatial index is up-to-date before hit testing
    controller.ensureIndexFresh();

    final tester = PolylineHitTester(
      cam,
      hitTolerance: widget.hitTolerance,
      index: controller.spatialIndex,
    );
    return tester.hit(
      polylines,
      offset,
      preferKey: controller.hoveredKey,
    );
  }

  void _onHover(PointerHoverEvent event, InteractivePolyline? polyline) {
    if (polyline != null) {
      controller.hover(polyline);
    } else {
      controller.clearHover();
    }
  }

  void _onTapUp(TapUpDetails details, InteractivePolyline? polyline) {
    if (polyline != null) {
      controller.tap(polyline);
    } else {
      controller.deselect();
    }
  }

  void _onSecondaryTapUp(TapUpDetails details, InteractivePolyline? polyline) {
    if (polyline != null) {
      controller.longPress(polyline);
    }
  }

  void _onDragStart(Offset offset, InteractivePolyline polyline) {
    controller.select(polyline);
    if (polyline.key != null) {
      controller.startDrag(polyline, cam.screenOffsetToLatLng(offset));
    }
  }

  void _onDragUpdate(Offset offset) {
    if (controller.transientState.value != null) {
      final to = cam.screenOffsetToLatLng(offset);
      controller.updateDrag(to);

      final draggedItem = controller.transientState.value?.item;
      if (draggedItem != null) {
        final state = controller.transientState.value!;
        final deltaLat = state.current.latitude - state.origin.latitude;
        final deltaLng = state.current.longitude - state.origin.longitude;

        final newPoints = draggedItem.points
            .map((p) => LatLng(p.latitude + deltaLat, p.longitude + deltaLng))
            .toList();
        final moved = draggedItem.copyWith(points: newPoints);

        _autoPanIfNeeded(moved);
      }
    } else {
      // fallback
    }
  }

  void _onDragEnd(Offset offset, InteractivePolyline polyline) {
    controller.endDrag();
    controller.longPress(polyline);
  }

  void _autoPanIfNeeded(InteractivePolyline moved) {
    final ap = controller.options.autoPanOnDrag;
    if (!ap.enabled) return;

    final view = Offset.zero & cam.nonRotatedSize;

    // Calculate pixel bounds of the polyline
    final points = moved.points.map(cam.latLngToScreenOffset).toList();
    if (points.isEmpty) return;

    final r = getBounds(points);

    final safe = Rect.fromLTWH(
      view.left + ap.safePadding.left,
      view.top + ap.safePadding.top,
      view.width - ap.safePadding.horizontal,
      view.height - ap.safePadding.vertical,
    );

    final correction = getPanCorrection(r, safe);
    if (correction == Offset.zero) return;

    final ox = correction.dx;
    final oy = correction.dy;

    double step(double v) {
      final s = ap.minStepPx + ap.gain * v.abs();
      return s.clamp(ap.minStepPx, ap.maxStepPx) * v.sign;
    }

    final delta = Offset(step(ox), step(oy));
    if (ap.animated) {
      map.panByOffsetAnimated(this, delta, ap.animationDuration);
    } else {
      map.panByOffset(delta);
    }
  }
}
