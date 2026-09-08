import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show Marker, MapCamera;
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/interactive_marker_layer.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/layers/options.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_map_interactive/overlays/utils/handle.dart';
import 'package:flutter_map_interactive/overlays/utils/overlay_geometry.dart';
import 'package:latlong2/latlong.dart';

class OverlayHandleLayer extends StatefulWidget {
  const OverlayHandleLayer({
    super.key,
    required this.overlays,
    this.options = const OverlayHandleOptions(),
  });

  /// Source of truth for corners (current overlays list).
  final List<InteractiveOverlayImage> overlays;

  final OverlayHandleOptions options;

  @override
  State<OverlayHandleLayer> createState() => _OverlayHandleLayerState();
}

class _OverlayHandleLayerState extends State<OverlayHandleLayer> {
  late OverlayController _overlayController;
  late final MarkerController _markerController;

  static const kTL = ValueKey('ov-handle-tl');
  static const kTR = ValueKey('ov-handle-tr');
  static const kBR = ValueKey('ov-handle-br');
  static const kBL = ValueKey('ov-handle-bl');

  static const kTop = ValueKey('ov-handle-top');
  static const kRight = ValueKey('ov-handle-right');
  static const kBottom = ValueKey('ov-handle-bottom');
  static const kLeft = ValueKey('ov-handle-left');

  static const kRotate = ValueKey('ov-handle-rotate');

  bool _initialized = false;
  bool _isAdjusting = false;

  Key? _lastActiveKey;
  QuadLatLng? _lastCorners;
  OverlayHandleOptions? _lastOptions;
  InteractiveOverlayImage? _dragStartOverlay;

  @override
  void initState() {
    super.initState();
    _markerController = MarkerController();
    _markerController.startEditMode();
    _markerController.addListener(_onHandlesChanged);
    _markerController.transientState.addListener(_onHandlesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = OverlayController.of(context);
    if (_initialized && _overlayController != newController) {
      _overlayController.removeListener(_onControllerChanged);
      _overlayController = newController;
      _overlayController.addListener(_onControllerChanged);
      _updateHandles();
    } else if (!_initialized) {
      _overlayController = newController;
      _overlayController.addListener(_onControllerChanged);
      _initialized = true;
      _updateHandles();
    }
  }

  @override
  void didUpdateWidget(covariant OverlayHandleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.overlays, widget.overlays) ||
        oldWidget.options != widget.options) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateHandles();
      });
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _overlayController.removeListener(_onControllerChanged);
    }
    _markerController.transientState.removeListener(_onHandlesChanged);
    _markerController.removeListener(_onHandlesChanged);
    _markerController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _updateHandles();
  }

  void _updateHandles() {
    if (_overlayController.isEditing &&
        !_overlayController.hasActive &&
        widget.overlays.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !_overlayController.isEditing ||
            _overlayController.hasActive ||
            widget.overlays.length != 1) {
          return;
        }
        _overlayController.select(widget.overlays.first);
      });
      return;
    }

    final active = _activeOverlay;
    if (active == null) {
      _markerController.setMarkers([], resetHistory: true);
      _lastActiveKey = null;
      _lastCorners = null;
      _lastOptions = null;
      _dragStartOverlay = null;
      return;
    }

    if (_lastActiveKey != active.key) {
      _dragStartOverlay = null;
    }

    if (_lastActiveKey == active.key &&
        _lastOptions == widget.options &&
        _lastCorners == active.corners) {
      return;
    }

    _lastActiveKey = active.key;
    _lastCorners = active.corners;
    _lastOptions = widget.options;
    _createHandlesFor(active);
  }

  InteractiveOverlayImage? get _activeOverlay {
    final activeKey = _overlayController.activeKey;
    if (activeKey == null) return null;
    for (final overlay in widget.overlays) {
      if (overlay.key == activeKey) return overlay;
    }
    return null;
  }

  void _onHandlesChanged() {
    if (!_overlayController.isEditing) return;

    final activeKey = _overlayController.activeKey;
    final active = _activeOverlay;
    if (activeKey == null || active == null) return;

    final drag = _markerController.transientState.value;
    if (drag == null) {
      _dragStartOverlay = null;
      return;
    }

    _dragStartOverlay ??= active;
    final startOverlay = _dragStartOverlay!;
    final cam = MapCamera.of(context);

    final dragKey = drag.item.key;
    final dragPos = drag.current;

    LatLng diff(LatLng a, LatLng b) =>
        LatLng(a.latitude - b.latitude, a.longitude - b.longitude);

    if (dragKey == kTL || dragKey == kTR || dragKey == kBR || dragKey == kBL) {
      if (dragKey == kTL) {
        _overlayController.moveCorner(
          activeKey,
          QuadCorner.topLeft,
          dragPos,
          merge: true,
        );
      }
      if (dragKey == kTR) {
        _overlayController.moveCorner(
          activeKey,
          QuadCorner.topRight,
          dragPos,
          merge: true,
        );
      }
      if (dragKey == kBR) {
        _overlayController.moveCorner(
          activeKey,
          QuadCorner.bottomRight,
          dragPos,
          merge: true,
        );
      }
      if (dragKey == kBL) {
        _overlayController.moveCorner(
          activeKey,
          QuadCorner.bottomLeft,
          dragPos,
          merge: true,
        );
      }
      return;
    }

    LatLng add(LatLng p, LatLng delta) =>
        LatLng(p.latitude + delta.latitude, p.longitude + delta.longitude);

    if (dragKey == kTop) {
      final totalDelta = diff(dragPos, startOverlay.corners.topMid);
      final newOverlay = startOverlay.copyWith(
        corners: startOverlay.corners.copyWith(
          topLeft: add(startOverlay.corners.topLeft, totalDelta),
          topRight: add(startOverlay.corners.topRight, totalDelta),
        ),
      );
      _overlayController.update(activeKey, newOverlay);
      return;
    }

    if (dragKey == kRight) {
      final totalDelta = diff(dragPos, startOverlay.corners.rightMid);
      final newOverlay = startOverlay.copyWith(
        corners: startOverlay.corners.copyWith(
          topRight: add(startOverlay.corners.topRight, totalDelta),
          bottomRight: add(startOverlay.corners.bottomRight, totalDelta),
        ),
      );
      _overlayController.update(activeKey, newOverlay);
      return;
    }

    if (dragKey == kBottom) {
      final totalDelta = diff(dragPos, startOverlay.corners.bottomMid);
      final newOverlay = startOverlay.copyWith(
        corners: startOverlay.corners.copyWith(
          bottomRight: add(startOverlay.corners.bottomRight, totalDelta),
          bottomLeft: add(startOverlay.corners.bottomLeft, totalDelta),
        ),
      );
      _overlayController.update(activeKey, newOverlay);
      return;
    }

    if (dragKey == kLeft) {
      final totalDelta = diff(dragPos, startOverlay.corners.leftMid);
      final newOverlay = startOverlay.copyWith(
        corners: startOverlay.corners.copyWith(
          bottomLeft: add(startOverlay.corners.bottomLeft, totalDelta),
          topLeft: add(startOverlay.corners.topLeft, totalDelta),
        ),
      );
      _overlayController.update(activeKey, newOverlay);
      return;
    }

    if (dragKey == kRotate) {
      Offset toScreen(LatLng l) => cam.latLngToScreenOffset(l);

      final pCenter = toScreen(startOverlay.center);
      final pRot = toScreen(dragPos);

      final angleCurrent =
          math.atan2(pRot.dy - pCenter.dy, pRot.dx - pCenter.dx);

      final startHandlePos = calcRotateHandlePos(startOverlay, cam);
      final pStartHandle = toScreen(startHandlePos);
      final angleStart = math.atan2(
        pStartHandle.dy - pCenter.dy,
        pStartHandle.dx - pCenter.dx,
      );

      var totalAngle = angleCurrent - angleStart;
      while (totalAngle > math.pi) {
        totalAngle -= 2 * math.pi;
      }
      while (totalAngle < -math.pi) {
        totalAngle += 2 * math.pi;
      }

      final newCorners =
          startOverlay.corners.rotate(totalAngle, anchor: startOverlay.center);
      final newOverlay = startOverlay.copyWith(corners: newCorners);
      _overlayController.update(activeKey, newOverlay);

      if (!_isAdjusting) {
        _isAdjusting = true;
        try {
          final constrainedPos = calcRotateHandlePos(newOverlay, cam);
          final dLat = constrainedPos.latitude - dragPos.latitude;
          final dLng = constrainedPos.longitude - dragPos.longitude;

          if (dLat * dLat + dLng * dLng > 1e-12) {
            _markerController.updateDrag(constrainedPos);
          }
        } finally {
          _isAdjusting = false;
        }
      }
    }
  }

  void _createHandlesFor(InteractiveOverlayImage overlay) {
    final corners = overlay.corners;
    final cam = MapCamera.of(context);
    final rotatePos = calcRotateHandlePos(overlay, cam);

    final handles = <Marker>[
      _createHandle(kTL, corners.topLeft, overlay, isCorner: true),
      _createHandle(kTR, corners.topRight, overlay, isCorner: true),
      _createHandle(kBR, corners.bottomRight, overlay, isCorner: true),
      _createHandle(kBL, corners.bottomLeft, overlay, isCorner: true),
      _createHandle(kTop, corners.topMid, overlay),
      _createHandle(kRight, corners.rightMid, overlay),
      _createHandle(kBottom, corners.bottomMid, overlay),
      _createHandle(kLeft, corners.leftMid, overlay),
      _createHandle(kRotate, rotatePos, overlay, isRotate: true),
    ];

    _markerController.setMarkers(handles, resetHistory: true);
  }

  EditHandle _createHandle(
    Key key,
    LatLng point,
    InteractiveOverlayImage overlay, {
    bool isCorner = false,
    bool isRotate = false,
  }) {
    if (isRotate) {
      return EditHandle(
        key: key,
        point: point,
        size: (overlay.handleSize ?? widget.options.size) * 1.5,
        icon: Icons.refresh,
        color: widget.options.color,
        borderColor: widget.options.borderColor,
        borderWidth: widget.options.borderWidth,
        activeColor: widget.options.activeColor,
        activeBorderColor: widget.options.activeBorderColor,
        activeBorderWidth: widget.options.activeBorderWidth,
        touchSizeFactor: widget.options.touchSizeFactor,
      );
    }

    return EditHandle(
      key: key,
      point: point,
      size: overlay.handleSize ?? widget.options.size,
      color: widget.options.color,
      borderColor: widget.options.borderColor,
      borderWidth: widget.options.borderWidth,
      activeColor: widget.options.activeColor,
      activeBorderColor: widget.options.activeBorderColor,
      activeBorderWidth: widget.options.activeBorderWidth,
      touchSizeFactor: widget.options.touchSizeFactor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeOverlay;
    if (active == null) return const SizedBox.shrink();

    if (_overlayController.transientState.value?.item.key == active.key) {
      return const SizedBox.shrink();
    }

    final cam = MapCamera.of(context);
    final topMid = active.corners.topMid;
    final rotatePos = calcRotateHandlePos(active, cam);

    return CustomPaint(
      painter: _ConnectorPainter(
        start: cam.latLngToScreenOffset(topMid),
        end: cam.latLngToScreenOffset(rotatePos),
        color: widget.options.connectorColor,
        width: widget.options.connectorWidth,
      ),
      child: InteractiveMarkerLayer(
        markers: _markerController.current,
        markerController: _markerController,
        options: const InteractiveOptions<Marker>(
          centerOnTap: false,
        ),
        markerOptions: const InteractiveLayerOptions(),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.width,
  });
  final Offset start;
  final Offset end;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if ((start - end).distanceSquared < 0.1) return;

    final casingPaint = Paint()
      ..color = const Color(0xAA111111)
      ..strokeWidth = width + 2.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final haloPaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..strokeWidth = width + 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawLine(start, end, casingPaint);
    canvas.drawLine(start, end, haloPaint);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return start != oldDelegate.start ||
        end != oldDelegate.end ||
        color != oldDelegate.color ||
        width != oldDelegate.width;
  }
}
