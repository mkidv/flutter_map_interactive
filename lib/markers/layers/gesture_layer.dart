import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' hide InteractionOptions;
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/utils/hit_tester.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:flutter_map_interactive/utils/hit_test_gesture_detector.dart';
import 'package:flutter_map_interactive/utils/rect_ops.dart';

class GestureLayer extends StatefulWidget {
  const GestureLayer({
    super.key,
    required this.markers,
    required this.options,
    required this.layerOptions,
  });
  final List<Marker> markers;
  final InteractiveOptions<Marker> options;
  final MarkerLayerOptions layerOptions;

  @override
  State<GestureLayer> createState() => _GestureLayerState();
}

class _GestureLayerState extends State<GestureLayer>
    with TickerProviderStateMixin {
  late MapCamera cam;
  late MarkerController controller;
  late MapController map;
  late InteractiveOptions<Marker> options;
  late MarkerLayerOptions layerOptions;
  late List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    cam = MapCamera.of(context);
    controller = MarkerController.of(context);
    map = MapController.of(context);
    options = widget.options;
    layerOptions = widget.layerOptions;
    markers = widget.markers;

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

        return HitTestableGestureDetector<Marker>(
          behavior: HitTestBehavior.translucent,
          hitTest: _hitOffset,
          onHover: canHover ? _onHover : null,
          onTapUp: canTap ? _onTapUp : null,
          onSecondaryTapUp: canLongPress ? _onSecondaryTapUp : null,
          onLongPressStart:
              canLongPress ? (d, m) => _onDragStart(d.localPosition, m) : null,
          onLongPressMoveUpdate:
              canLongPress ? (d, _) => _onDragUpdate(d.localPosition) : null,
          onLongPressEnd:
              canLongPress ? (d, m) => _onDragEnd(d.localPosition, m) : null,
          onPanStart:
              canDrag ? (d, m) => _onDragStart(d.localPosition, m) : null,
          onPanUpdate:
              canDrag ? (d, _) => _onDragUpdate(d.localPosition) : null,
          onPanEnd: canDrag ? (d, m) => _onDragEnd(d.localPosition, m) : null,
        );
      },
    );
  }

  Marker? _hitOffset(Offset offset) {
    // Ensure spatial index is up-to-date before hit testing
    controller.ensureIndexFresh();

    final tester =
        MarkerHitTester(cam, layerOptions, index: controller.spatialIndex);
    return tester.hit(
      markers,
      offset,
      preferKey: controller.hoveredKey,
      isActiveKey: controller.isActiveKey,
    );
  }

  void _onHover(PointerHoverEvent event, Marker? marker) {
    if (marker != null) {
      controller.hover(marker);
    } else {
      controller.clearHover();
    }
  }

  void _onTapUp(TapUpDetails details, Marker? marker) {
    if (marker != null) {
      controller.tap(marker);
      if (options.centerOnTap) {
        map.centerMarkerAnimated(this, marker);
      }
    } else {
      if (controller.isEditing && options.moveOnTap) {
        _moveToOffset(details.localPosition, false);
      } else {
        controller.deselect();
      }
    }
  }

  void _onSecondaryTapUp(TapUpDetails details, Marker? marker) {
    if (marker != null) controller.longPress(marker);
  }

  void _onDragStart(Offset offset, Marker marker) {
    controller.select(marker);
    controller.startDrag(marker, cam.screenOffsetToLatLng(offset));
  }

  void _onDragUpdate(Offset offset) {
    if (controller.activeKey == null) return;
    controller.updateDrag(cam.screenOffsetToLatLng(offset));
  }

  void _onDragEnd(Offset offset, Marker marker) {
    controller.endDrag();
    controller.longPress(marker);
  }

  void _autoPanIfNeeded(Marker moved) {
    final ap = options.autoPanOnDrag;
    if (!ap.enabled) return;

    final view = Offset.zero & cam.nonRotatedSize;
    final r = moved.pixelBounds(cam,
        options: layerOptions, active: controller.isActiveKey(moved.key));

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

  void _moveToOffset(Offset offset, bool drag) {
    final key = controller.activeKey;
    if (key == null) return;
    final to = cam.screenOffsetToLatLng(offset);
    controller.move(key, to, merge: drag);
    final moved = controller.current.findByKey(key);
    _autoPanIfNeeded(moved);
    if (!drag) {
      controller.deselect();
    }
  }
}
