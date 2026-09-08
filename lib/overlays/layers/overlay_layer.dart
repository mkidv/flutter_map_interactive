import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/layers/options.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_map_interactive/overlays/utils/painter.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';

class OverlayLayer extends StatelessWidget {
  const OverlayLayer({
    super.key,
    required this.overlays,
    required this.options,
  });
  final List<InteractiveOverlayImage> overlays;
  final OverlayLayerOptions options;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final overlay in overlays)
          _OverlayItem(
            key: overlay.key,
            overlay: overlay,
            options: options,
          ),
      ],
    );
  }
}

class _OverlayItem extends StatefulWidget {
  const _OverlayItem({
    super.key,
    required this.overlay,
    required this.options,
  });
  final InteractiveOverlayImage overlay;
  final OverlayLayerOptions options;

  @override
  State<_OverlayItem> createState() => _OverlayItemState();
}

class _OverlayItemState extends State<_OverlayItem> {
  ui.Image? _img;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolve(widget.overlay.image);
  }

  @override
  void didUpdateWidget(covariant _OverlayItem old) {
    super.didUpdateWidget(old);
    if (old.overlay.image != widget.overlay.image) {
      _resolve(widget.overlay.image);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _detach() {
    final s = _stream;
    final l = _listener;
    if (s != null && l != null) s.removeListener(l);
    _stream = null;
    _listener = null;
  }

  void _resolve(ImageProvider provider) {
    _detach();
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _img = info.image);
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);
    final controller = OverlayController.of(context);

    return ListenableSelector(
      listenable: controller,
      select: (c) => (
        c.isActiveKey(widget.overlay.key),
        c.isHoveredKey(widget.overlay.key)
      ),
      builder: (context, state) {
        final (isActive, isHovered) = state;

        // Custom builder (comme MarkerLayerOptions.builder)
        // final custom = widget.options.builder?.call(context, controller, widget.overlay);
        // if (custom != null) return custom;

        final img = _img;
        if (img == null) return const SizedBox.shrink();

        final tl = cam.latLngToScreenOffset(widget.overlay.corners.topLeft);
        final tr = cam.latLngToScreenOffset(widget.overlay.corners.topRight);
        final br = cam.latLngToScreenOffset(widget.overlay.corners.bottomRight);
        final bl = cam.latLngToScreenOffset(widget.overlay.corners.bottomLeft);

        return Positioned.fill(
          child: CustomPaint(
            isComplex: true,
            willChange: isActive,
            painter: QuadVerticesPainter(
              image: img,
              tl: tl,
              tr: tr,
              br: br,
              bl: bl,
              alpha: (widget.overlay.alpha * widget.options.alpha) ~/ 255,
              filterQuality: widget.options.filterQuality,
              drawOutline: widget.options.showActiveOutline && isActive,
              outlineColor: widget.options.activeOutlineColor,
              outlineWidth: widget.options.activeOutlineWidth,
              glow: isHovered,
            ),
          ),
        );
      },
    );
  }
}
