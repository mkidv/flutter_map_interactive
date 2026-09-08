import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide InteractionOptions;
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/markers/interactive_marker_layer.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/overlays/utils/handle.dart';
import 'package:flutter_map_interactive/polylines/controllers/polyline_controller.dart';
import 'package:flutter_map_interactive/polylines/interactive_polyline_scope.dart';
import 'package:flutter_map_interactive/polylines/layers/options.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:latlong2/latlong.dart';

class PolylineHandleLayer extends StatefulWidget {
  const PolylineHandleLayer({
    super.key,
    required this.polylines,
    this.polylineController,
    this.options = const PolylineHandleOptions(),
  });

  /// Source of truth for polylines.
  final List<InteractivePolyline> polylines;

  final PolylineController? polylineController;
  final PolylineHandleOptions options;

  @override
  State<PolylineHandleLayer> createState() => _PolylineHandleLayerState();
}

class _PolylineHandleLayerState extends State<PolylineHandleLayer> {
  late PolylineController _polylineController;
  late final MarkerController _markerController;

  bool _initialized = false;

  Key? _lastActiveKey;
  List<LatLng>? _lastPoints;
  PolylineHandleOptions? _lastOptions;

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
    final newController = widget.polylineController ??
        InteractivePolylineScope.controllerOf(context);
    if (_initialized && _polylineController != newController) {
      _polylineController.removeListener(_onControllerChanged);
      _polylineController = newController;
      _polylineController.addListener(_onControllerChanged);
      _updateHandles();
    } else if (!_initialized) {
      _polylineController = newController;
      _polylineController.addListener(_onControllerChanged);
      _initialized = true;
      _updateHandles();
    }
  }

  @override
  void didUpdateWidget(covariant PolylineHandleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.polylines, widget.polylines) ||
        oldWidget.options != widget.options ||
        oldWidget.polylineController != widget.polylineController) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateHandles();
      });
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _polylineController.removeListener(_onControllerChanged);
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
    if (_polylineController.isEditing &&
        !_polylineController.hasActive &&
        widget.polylines.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !_polylineController.isEditing ||
            _polylineController.hasActive ||
            widget.polylines.length != 1) {
          return;
        }
        _polylineController.select(widget.polylines.first);
      });
      return;
    }

    final activeKey = _polylineController.activeKey;
    final active = widget.polylines.firstWhereOrNull((p) => p.key == activeKey);

    if (active == null) {
      if (_markerController.current.isNotEmpty) {
        _markerController.setMarkers([], resetHistory: true);
      }
      _lastActiveKey = null;
      _lastPoints = null;
      _lastOptions = null;
      return;
    }

    if (_lastActiveKey == active.key &&
        _lastOptions == widget.options &&
        _lastPoints != null &&
        const ListEquality<LatLng>().equals(active.points, _lastPoints)) {
      return;
    }

    _lastActiveKey = active.key;
    _lastPoints = List<LatLng>.of(active.points);
    _lastOptions = widget.options;

    _createHandlesFor(active);
  }

  void _createHandlesFor(InteractivePolyline polyline) {
    final handles = <Marker>[];
    for (int i = 0; i < polyline.points.length; i++) {
      handles.add(_createHandle(i, polyline.points[i]));
    }
    _markerController.setMarkers(handles, resetHistory: true);
  }

  Marker _createHandle(int index, LatLng point) {
    return EditHandle(
      key: ValueKey('v_$index'),
      point: point,
      size: widget.options.size,
      color: widget.options.color,
      borderColor: widget.options.borderColor,
      borderWidth: widget.options.borderWidth,
      activeColor: widget.options.activeColor,
      activeBorderColor: widget.options.activeBorderColor,
      activeBorderWidth: widget.options.activeBorderWidth,
      touchSizeFactor: widget.options.touchSizeFactor,
    );
  }

  void _onHandlesChanged() {
    if (!_polylineController.isEditing) return;

    final activeKey = _polylineController.activeKey;
    if (activeKey == null) return;

    final active = widget.polylines.firstWhereOrNull((p) => p.key == activeKey);
    if (active == null) return;

    final drag = _markerController.transientState.value;
    if (drag == null) return;

    final key = drag.item.key;
    if (key is ValueKey<String>) {
      final value = key.value;
      if (value.startsWith('v_')) {
        final idx = int.tryParse(value.substring(2));
        if (idx != null && idx >= 0 && idx < active.points.length) {
          final newPoints = List<LatLng>.of(active.points);
          newPoints[idx] = drag.current;

          final updatedPolyline = active.copyWith(points: newPoints);
          _polylineController.update(active.key!, updatedPolyline);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeKey = _polylineController.activeKey;
    if (activeKey == null) return const SizedBox.shrink();

    if (_polylineController.transientState.value?.item.key == activeKey) {
      return const SizedBox.shrink();
    }

    return InteractiveMarkerLayer(
      markers: _markerController.current,
      markerController: _markerController,
      options: const InteractiveOptions<Marker>(
        centerOnTap: false,
      ),
      markerOptions: const InteractiveLayerOptions(),
    );
  }
}
