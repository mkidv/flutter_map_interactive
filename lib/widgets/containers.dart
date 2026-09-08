import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapContainer extends StatefulWidget {
  const FlutterMapContainer({
    super.key,
    required this.child,
    required this.camera,
    required this.point,
    this.alignment = Alignment.center,
    this.rotate = true,
    this.margin,
    this.width,
    this.height,
    this.glow = false,
    this.glowOverlay = const GlowOverlay(),
    this.pixelOffset = Offset.zero,
    this.onMeasured,
  });
  final Widget child;
  final MapCamera camera;
  final LatLng point;
  final Alignment alignment;
  final bool rotate;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool glow;
  final Widget glowOverlay;
  final Offset pixelOffset;
  final void Function(Key key, Size size)? onMeasured;

  @override
  State<FlutterMapContainer> createState() => _FlutterMapContainerState();
}

class _FlutterMapContainerState extends State<FlutterMapContainer> {
  Size? _measured;
  bool _inMobileLayerTransformer = false;

  Size? get _effectiveSize {
    if (widget.width != null && widget.height != null) {
      return Size(widget.width!, widget.height!);
    }
    return _measured;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inMobileLayerTransformer = isInMobileLayer(context);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedMargin =
        (widget.margin ?? EdgeInsets.zero).resolve(Directionality.of(context));
    final childToMeasure = MeasureSize(
      onChange: (value) {
        setState(() => _measured = value);
        final idKey =
            widget.child.key ?? widget.key ?? const ValueKey('__auto__');
        widget.onMeasured?.call(idKey, value);
      },
      child: widget.child,
    );

    final effectiveSize = _effectiveSize;
    final content = (widget.width != null && widget.height != null)
        ? SizedBox(
            width: widget.width, height: widget.height, child: childToMeasure)
        : childToMeasure;

    if (effectiveSize == null) {
      return Offstage(child: content);
    }

    final origin = _inMobileLayerTransformer
        ? widget.camera.latLngToLayerOffset(widget.point)
        : widget.camera.latLngToScreenOffset(widget.point);

    final mat = overlayMatrix(
      origin: origin,
      size: effectiveSize,
      alignment: widget.alignment,
      mapRotationRad: widget.camera.rotationRad,
      rotate: widget.rotate,
      margin: resolvedMargin,
      pixelOffset: widget.pixelOffset,
    );

    return Transform(
      transform: mat,
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: widget.alignment,
          children: [
            if (widget.glow) Positioned.fill(child: widget.glowOverlay),
            content,
          ],
        ),
      ),
    );
  }
}

class FlutterMapAnimatedContainer extends StatefulWidget {
  const FlutterMapAnimatedContainer({
    super.key,
    required this.child,
    required this.camera,
    required this.point,
    this.alignment = Alignment.center,
    this.rotate = true,
    this.margin,
    this.width,
    this.height,
    this.animationBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
    this.animation,
    this.controller,
    this.animateOnMount = true,
    this.restartOnPointChange = true,
    this.restartOnChildChange = true,
    this.glow = false,
    this.glowOverlay = const GlowOverlay(),
    this.pixelOffset = Offset.zero,
    this.onMeasured,
  }) : assert(animation == null || controller == null,
            'Use either animation OR controller, not both.');
  final Widget? child;
  final MapCamera camera;
  final LatLng point;
  final Alignment alignment;
  final bool rotate;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool glow;
  final Widget glowOverlay;
  final Offset pixelOffset;
  final void Function(Key key, Size size)? onMeasured;

  // Animation
  final Duration animationDuration;
  final Curve animationCurve;
  final Animation<double>? animation;
  final AnimationController? controller;
  final bool animateOnMount;
  final bool restartOnPointChange;
  final bool restartOnChildChange;

  final Widget Function(
          BuildContext context, Animation<double> anim, Widget? child)?
      animationBuilder;

  @override
  State<FlutterMapAnimatedContainer> createState() =>
      _FlutterMapAnimatedContainerState();
}

class _FlutterMapAnimatedContainerState
    extends State<FlutterMapAnimatedContainer>
    with SingleTickerProviderStateMixin {
  AnimationController? _ownedCtrl;
  late Animation<double> _anim;

  AnimationController get _ctrl => widget.controller ?? _ownedCtrl!;
  bool get _ownsController =>
      widget.controller == null && widget.animation == null;

  @override
  void initState() {
    super.initState();
    _ensureController();
    _rebuildAnim();

    if (widget.animateOnMount && _ownsController) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ctrl.forward(from: 0));
    }
  }

  void _ensureController() {
    if (widget.animation != null) return;
    if (widget.controller != null) return;
    _ownedCtrl =
        AnimationController(vsync: this, duration: widget.animationDuration);
  }

  void _rebuildAnim() {
    _anim = widget.animation ??
        CurvedAnimation(parent: _ctrl, curve: widget.animationCurve);
  }

  @override
  void didUpdateWidget(covariant FlutterMapAnimatedContainer old) {
    super.didUpdateWidget(old);

    if (_ownsController && old.animationDuration != widget.animationDuration) {
      _ctrl.duration = widget.animationDuration;
    }

    final curveChanged = old.animationCurve != widget.animationCurve;
    final animSourceChanged = old.animation != widget.animation;
    if (curveChanged || animSourceChanged) {
      _rebuildAnim();
    }

    final moved =
        widget.point != old.point || widget.pixelOffset != old.pixelOffset;
    final childChanged = widget.child?.key != old.child?.key;
    if (_ownsController &&
        ((widget.restartOnPointChange && moved) ||
            (widget.restartOnChildChange && childChanged))) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ownedCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.animationBuilder != null
        ? widget.animationBuilder!(context, _anim, widget.child)
        : FadeTransition(
            opacity: _anim.drive(Tween(begin: 0.0, end: 1.0)),
            child: ScaleTransition(
              scale: _anim.drive(Tween(begin: 0.8, end: 1.0)),
              alignment: widget.alignment,
              child: widget.child,
            ),
          );

    return FlutterMapContainer(
      camera: widget.camera,
      point: widget.point,
      alignment: widget.alignment,
      rotate: widget.rotate,
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      glow: widget.glow,
      glowOverlay: widget.glowOverlay,
      pixelOffset: widget.pixelOffset,
      onMeasured: widget.onMeasured,
      child: child,
    );
  }
}

class GlowOverlay extends StatelessWidget {
  const GlowOverlay(
      {super.key,
      this.color = const Color(0xFFFFFFFF),
      this.alpha = 120,
      this.blurRadius = 16.0,
      this.spreadRadius = 2.0});
  final Color color;
  final int alpha;
  final double blurRadius;
  final double spreadRadius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(alpha),
              blurRadius: blurRadius,
              spreadRadius: spreadRadius,
            ),
          ],
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, required Widget child})
      : super(child: child);
  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);
  ValueChanged<Size> onChange;
  Size? _oldSize;
  bool _scheduled = false;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize || _scheduled) return;
    _oldSize = newSize;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (attached) onChange(newSize);
    });
  }
}
