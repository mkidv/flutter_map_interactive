import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show MapCamera, MapController;
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_map_interactive/overlays/utils/hit_tester.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/utils/hit_test_gesture_detector.dart';
import 'package:flutter_map_interactive/utils/rect_ops.dart';

class OverlayGestureLayer extends StatefulWidget {
  const OverlayGestureLayer({
    super.key,
    required this.overlays,
    this.quadHitPaddingPx = 6.0,
  });

  final List<InteractiveOverlayImage> overlays;
  final double quadHitPaddingPx;

  @override
  State<OverlayGestureLayer> createState() => _OverlayGestureLayerState();
}

class _OverlayGestureLayerState extends State<OverlayGestureLayer>
    with TickerProviderStateMixin {
  late MapCamera cam;
  late OverlayController controller;
  late MapController map;
  late List<InteractiveOverlayImage> overlays;

  @override
  Widget build(BuildContext context) {
    cam = MapCamera.of(context);
    controller = OverlayController.of(context);
    map = MapController.of(context);
    overlays = widget.overlays;

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

        return HitTestableGestureDetector<InteractiveOverlayImage>(
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

  InteractiveOverlayImage? _hitOffset(Offset offset) {
    // Ensure spatial index is up-to-date before hit testing
    controller.ensureIndexFresh();

    final tester = OverlayHitTester(cam,
        quadPaddingPx: widget.quadHitPaddingPx, index: controller.spatialIndex);
    return tester.hit(
      overlays,
      offset,
      preferKey: controller.hoveredKey,
    );
  }

  void _onHover(PointerHoverEvent event, InteractiveOverlayImage? overlay) {
    if (overlay != null) {
      controller.hover(overlay);
    } else {
      controller.clearHover();
    }
  }

  void _onTapUp(TapUpDetails details, InteractiveOverlayImage? overlay) {
    if (overlay != null) {
      controller.tap(overlay);
    } else {
      controller.deselect();
    }
  }

  void _onSecondaryTapUp(
      TapUpDetails details, InteractiveOverlayImage? overlay) {
    if (overlay != null) {
      controller.longPress(overlay);
    }
  }

  void _onDragStart(Offset offset, InteractiveOverlayImage overlay) {
    controller.select(overlay);
    if (overlay.key != null) {
      controller.startDrag(overlay, cam.screenOffsetToLatLng(offset));
    }
  }

  void _onDragUpdate(Offset offset) {
    if (controller.transientState.value != null) {
      final to = cam.screenOffsetToLatLng(offset);
      controller.updateDrag(to);

      final draggedItem = controller.transientState.value?.item;
      // We need to construct the moved item to check boundaries for auto-pan
      // The item in dragState is the ORIGINAL.
      // Actually we need the CURRENT position.
      // DragState has 'origin' and 'current'.
      // We can assume the proxy layer logic: offset = current - origin.
      if (draggedItem != null) {
        final state = controller.transientState.value!;
        final deltaLat = state.current.latitude - state.origin.latitude;
        final deltaLng = state.current.longitude - state.origin.longitude;
        final moved = draggedItem.copyWith(
          corners: draggedItem.corners.translate(deltaLat, deltaLng),
        );
        _autoPanIfNeeded(moved);
      }
    } else {
      // Fallback for non-keyed or failed start (shouldn't happen often if we enforce keys)
    }
  }

  void _onDragEnd(Offset offset, InteractiveOverlayImage overlay) {
    controller.endDrag();
    controller.longPress(overlay);
  }

  void _autoPanIfNeeded(InteractiveOverlayImage moved) {
    final ap = controller.options.autoPanOnDrag;
    if (!ap.enabled) return;

    final view = Offset.zero & cam.nonRotatedSize;

    // Calculate pixel bounds of the overlay
    final tl = cam.latLngToScreenOffset(moved.corners.topLeft);
    final tr = cam.latLngToScreenOffset(moved.corners.topRight);
    final br = cam.latLngToScreenOffset(moved.corners.bottomRight);
    final bl = cam.latLngToScreenOffset(moved.corners.bottomLeft);
    final r = getBounds([tl, tr, br, bl]);

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
