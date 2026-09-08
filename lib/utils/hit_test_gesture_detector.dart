import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

typedef HitTestCallback<T> = T? Function(Offset localPosition);
typedef TapUpWithDataCallback<T> = void Function(TapUpDetails details, T? data);
typedef DragStartWithDataCallback<T> = void Function(
    DragStartDetails details, T data);
typedef DragUpdateWithDataCallback<T> = void Function(
    DragUpdateDetails details, T data);
typedef DragEndWithDataCallback<T> = void Function(
    DragEndDetails details, T data);
typedef LongPressStartWithDataCallback<T> = void Function(
    LongPressStartDetails details, T data);
typedef LongPressMoveUpdateWithDataCallback<T> = void Function(
    LongPressMoveUpdateDetails details, T data);
typedef LongPressEndWithDataCallback<T> = void Function(
    LongPressEndDetails details, T data);
typedef HoverWithDataCallback<T> = void Function(
    PointerHoverEvent event, T? data);

/// A Gesture Detector that uses a [Listener] for taps (to capture hits and misses without blocking
/// the gesture arena for underlying layers) and a [RawGestureDetector] for drags/long-presses
/// (which require arena participation to claim the gesture from the Map).
///
/// [hitTest] returns the data associated with the hit object (or null if miss).
///
/// Taps:
/// - Handled by [Listener].
/// - Fired for BOTH hits and misses.
/// - Passes [T?] to callbacks (allowing "Deselect" or "Move on Tap" logic).
/// - Does NOT block map clicks or other layers.
///
/// Drags (Pan) & LongPress:
/// - Handled by [RawGestureDetector].
/// - Fired ONLY for hits (Result != null).
/// - This prevents the detector from blocking Map Panning when dragging on empty space.
class HitTestableGestureDetector<T extends Object> extends StatefulWidget {
  const HitTestableGestureDetector({
    super.key,
    required this.hitTest,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onTapUp,
    this.onSecondaryTapUp,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onHover,
    this.child,
    this.behavior,
  });
  final HitTestCallback<T> hitTest;
  final DragStartWithDataCallback<T>? onPanStart;
  final DragUpdateWithDataCallback<T>? onPanUpdate;
  final DragEndWithDataCallback<T>? onPanEnd;
  final TapUpWithDataCallback<T>? onTapUp;
  final TapUpWithDataCallback<T>? onSecondaryTapUp;
  final LongPressStartWithDataCallback<T>? onLongPressStart;
  final LongPressMoveUpdateWithDataCallback<T>? onLongPressMoveUpdate;
  final LongPressEndWithDataCallback<T>? onLongPressEnd;
  final HoverWithDataCallback<T>? onHover;
  final Widget? child;
  final HitTestBehavior? behavior;

  @override
  State<HitTestableGestureDetector<T>> createState() =>
      _HitTestableGestureDetectorState<T>();
}

class _HitTestableGestureDetectorState<T extends Object>
    extends State<HitTestableGestureDetector<T>> {
  Offset? _downPosition;
  int? _downButtons;

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTapUp == null && widget.onSecondaryTapUp == null) return;
    _downPosition = event.localPosition;
    _downButtons = event.buttons;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_downPosition == null) return;

    final downPos = _downPosition!;
    _downPosition = null; // reset

    // Check distance (Slop) to ensure it's a tap, not a drag release
    final distance = (event.localPosition - downPos).distance;
    if (distance > kTouchSlop) return;

    // Use down position for hit test consistency
    final data = widget.hitTest(downPos);

    final details = TapUpDetails(
      kind: event.kind,
      globalPosition: event.position,
      localPosition: event.localPosition,
    );

    if (_downButtons == kSecondaryButton) {
      widget.onSecondaryTapUp?.call(details, data);
    } else {
      widget.onTapUp?.call(details, data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gestures = <Type, GestureRecognizerFactory>{};

    if (widget.onPanStart != null ||
        widget.onPanUpdate != null ||
        widget.onPanEnd != null) {
      gestures[HitTestablePanGestureRecognizer<T>] =
          GestureRecognizerFactoryWithHandlers<
              HitTestablePanGestureRecognizer<T>>(
        () => HitTestablePanGestureRecognizer<T>(hitTest: widget.hitTest),
        (instance) {
          instance.onStart = (d) {
            if (instance.hitData != null) {
              widget.onPanStart?.call(d, instance.hitData as T);
            }
          };
          instance.onUpdate = (d) {
            if (instance.hitData != null) {
              widget.onPanUpdate?.call(d, instance.hitData as T);
            }
          };
          instance.onEnd = (d) {
            if (instance.hitData != null) {
              widget.onPanEnd?.call(d, instance.hitData as T);
            }
          };
        },
      );
    }

    if (widget.onLongPressStart != null) {
      gestures[HitTestableLongPressGestureRecognizer<T>] =
          GestureRecognizerFactoryWithHandlers<
              HitTestableLongPressGestureRecognizer<T>>(
        () => HitTestableLongPressGestureRecognizer<T>(hitTest: widget.hitTest),
        (instance) {
          instance.onLongPressStart = (d) {
            if (instance.hitData != null) {
              widget.onLongPressStart?.call(d, instance.hitData as T);
            }
          };
          instance.onLongPressMoveUpdate = (d) {
            if (instance.hitData != null) {
              widget.onLongPressMoveUpdate?.call(d, instance.hitData as T);
            }
          };
          instance.onLongPressEnd = (d) {
            if (instance.hitData != null) {
              widget.onLongPressEnd?.call(d, instance.hitData as T);
            }
          };
        },
      );
    }


    final raw = RawGestureDetector(
      gestures: gestures,
      behavior: widget.behavior ?? HitTestBehavior.translucent,
      child: widget.child,
    );

    final listener = Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      behavior: widget.behavior ?? HitTestBehavior.translucent,
      child: raw,
    );

    if (widget.onHover != null) {
      return MouseRegion(
        hitTestBehavior: widget.behavior ?? HitTestBehavior.translucent,
        onHover: (event) {
          final data = widget.hitTest(event.localPosition);
          widget.onHover?.call(event, data);
        },
        child: listener,
      );
    }

    return listener;
  }
}

class HitTestablePanGestureRecognizer<T> extends PanGestureRecognizer {
  HitTestablePanGestureRecognizer({required this.hitTest, super.debugOwner});
  final HitTestCallback<T> hitTest;
  T? hitData;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final data = hitTest(event.localPosition);
    hitData = data;
    if (data != null) {
      super.addAllowedPointer(event);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    hitData = null;
    super.didStopTrackingLastPointer(pointer);
  }
}

class HitTestableLongPressGestureRecognizer<T>
    extends LongPressGestureRecognizer {
  HitTestableLongPressGestureRecognizer({
    required this.hitTest,
    this.buttons = kPrimaryButton,
    super.debugOwner,
  }) : super(postAcceptSlopTolerance: null);
  final HitTestCallback<T> hitTest;
  T? hitData;
  final int buttons;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final data = hitTest(event.localPosition);
    hitData = data;
    if (data != null) {
      super.addAllowedPointer(event);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    hitData = null;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (event.buttons != buttons) return false;
    return super.isPointerAllowed(event);
  }
}
