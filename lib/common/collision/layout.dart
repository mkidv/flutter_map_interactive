import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/painter.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';
import 'package:flutter_map_interactive/widgets/containers.dart';
import 'package:latlong2/latlong.dart';

/// Signature for building a list of collision nodes for the layer.
typedef CollisionNodesBuilder<T> = List<CollisionNode<T>> Function(
    BuildContext context, MapCamera cam);

/// Signature for building a widget for a collision node at its placement.
typedef CollisionItemBuilder<T> = Widget? Function(
  BuildContext context,
  MapCamera cam,
  CollisionNode<T> node,
  CollisionPlacement placement,
);

/// Defines bitmask constants for various collision layers in the map widget.
/// Each layer represents a specific interactive or visual element that can be
/// managed independently for hit-testing, rendering, or event handling.
///
/// Layers include:
/// - `label`: Marker labels.
/// - `anchor`: Marker/anchor hitboxes.
/// - `popup`: Popups for multi-select or info.
/// - `action`: Action menus or buttons.
/// - `handle`: Handles for resize, rotate, or drag.
/// - `hud`: Heads-up display elements (legend, scale bar).
/// - `polylineLabel`: Labels on polylines/routes.
/// - `polygonLabel`: Labels at polygon centroids.
/// - `cluster`: Cluster halos or badges.
/// - `tooltip`: Ephemeral tooltips.
/// - `selectionHalo`: Selection halos.
/// - `userLocation`: User location indicators (GPS dot, compass, etc.).
/// - `debug`: Debug overlays.
class CollisionLayerBits {
  static const int label = 1 << 0;
  static const int anchor = 1 << 1;

  static const int popup = 1 << 2;
  static const int action = 1 << 3;
  static const int handle = 1 << 4;
  static const int hud = 1 << 5;
  static const int polylineLabel = 1 << 6;
  static const int polygonLabel = 1 << 7;
  static const int cluster = 1 << 8;
  static const int tooltip = 1 << 9;
  static const int selectionHalo = 1 << 10;
  static const int userLocation = 1 << 11;
  static const int debug = 1 << 12;

  static const int any = 0xFFFFFFFF;
}

/// Represents a node/item that can participate in collision detection.
/// Contains position, size, category, and other metadata.
class CollisionNode<T> {
  const CollisionNode({
    required this.key,
    required this.anchor,
    this.alignment = Alignment.center,
    this.margin,
    this.rotate = false,
    this.knownSize,
    this.measureBuilder,
    this.priority = 10,
    this.category = CollisionLayerBits.label,
    this.collisionMask = CollisionLayerBits.label | CollisionLayerBits.anchor,
    this.anchorRectPx,
    this.drawConnector = true,
    this.data,
  });
  final Key key;
  final LatLng anchor;
  final Alignment alignment;
  final EdgeInsets? margin;
  final bool rotate;
  final Size? knownSize;
  final WidgetBuilder? measureBuilder; // if unknow size
  final int priority; // 0: top
  final int category;
  final int collisionMask;
  final Rect? anchorRectPx;
  final bool drawConnector;
  final T? data;
}

/// Stores the placement (offset and center) of a collision node after layout.
class CollisionPlacement {
  // new center
  const CollisionPlacement(
      {required this.key, required this.offsetPx, required this.centerPx, this.showConnector = true,});
  final Key key;
  final Offset offsetPx; // offset on origin
  final Offset centerPx;
    final bool showConnector;

}

/// Main widget for managing collision-aware placement.
/// Handles measuring, layout, and rendering of nodes with collision avoidance.
class CollisionLayoutBuilder<T> extends StatefulWidget {
  const CollisionLayoutBuilder({
    super.key,
    required this.buildNodes,
    required this.builder,
    this.options = const CollisionOptions(),
    this.strategy = const RadialFanStrategy(),
    this.repaint,
  });
  final CollisionNodesBuilder<T> buildNodes;
  final CollisionItemBuilder<T> builder;
  final CollisionOptions options;
  final CollisionStrategy strategy;
  final Listenable? repaint;

  @override
  State<CollisionLayoutBuilder<T>> createState() =>
      _CollisionLayoutBuilderState<T>();
}

class _CollisionLayoutBuilderState<T> extends State<CollisionLayoutBuilder<T>> {
  final _sizeCache = <Key, Size>{};
  final _offsetCache = <Key, Offset>{};
  final _grid = SpatialHashGrid();

  List<CollisionNode<T>> _nodes = const [];
  List<CollisionPlacement> _placements = const [];
  _ViewSig? _lastSig;
  Listenable? _repaint;

  @override
  void initState() {
    super.initState();
    assert(!isInMobileLayer(context),
        "CollisionLayoutBuilder can't be used in MobileLayerTransformer");
    _attachRepaint();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalcAndRedraw());
  }

  @override
  void didUpdateWidget(covariant CollisionLayoutBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repaint != widget.repaint) {
      _detachRepaint();
      _attachRepaint();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalcAndRedraw());
  }

  @override
  void dispose() {
    _detachRepaint();
    super.dispose();
  }

  void _attachRepaint() {
    _repaint = widget.repaint;
    _repaint?.addListener(_onRepaint);
  }

  void _detachRepaint() {
    _repaint?.removeListener(_onRepaint);
    _repaint = null;
  }

  void _onRepaint() {
    _recompute(force: true);
    if (mounted) setState(() {});
  }

  void _recompute({bool force = false}) {
    final cam = MapCamera.of(context);
    final s = cam.nonRotatedSize;

    _nodes = _buildResolvedNodes(cam, s);
    _pruneCaches(_nodes.map((node) => node.key));

    final scene = _ViewSig(
      cam.zoom,
      cam.rotation,
      s.width,
      s.height,
      cam.center.latitude,
      cam.center.longitude,
      widget.options.hashCode,
      _nodesSignature(_nodes),
    );

    if (!force && scene == _lastSig) return;

    _placements = widget.strategy.place(
      cam: cam,
      viewport: s,
      nodes: _nodes,
      options: widget.options,
      grid: _grid,
      previousOffsets: _offsetCache,
    );

    for (final p in _placements) {
      _offsetCache[p.key] = p.offsetPx;
    }

    _lastSig = scene;
  }

  void _pruneCaches(Iterable<Key> activeKeys) {
    final keep = activeKeys.toSet();
    _sizeCache.removeWhere((key, value) => !keep.contains(key));
    _offsetCache.removeWhere((key, value) => !keep.contains(key));
  }

  List<CollisionNode<T>> _buildResolvedNodes(MapCamera cam, Size viewport) {
    return widget.buildNodes(context, cam).map((n) {
      final known = n.knownSize ?? _sizeCache[n.key];
      return CollisionNode<T>(
        key: n.key,
        anchor: n.anchor,
        alignment: n.alignment,
        margin: n.margin,
        rotate: n.rotate,
        knownSize: known,
        measureBuilder: n.measureBuilder,
        priority: n.priority,
        category: n.category,
        collisionMask: n.collisionMask,
        anchorRectPx: n.anchorRectPx,
        drawConnector: n.drawConnector,
        data: n.data,
      );
    }).where((n) {
      final ex = widget.options.maxRadius + 128;
      final p = cam.latLngToScreenOffset(n.anchor);
      return p.dx >= -ex &&
          p.dx <= viewport.width + ex &&
          p.dy >= -ex &&
          p.dy <= viewport.height + ex;
    }).toList();
  }

  int _nodesSignature(List<CollisionNode<T>> nodes) {
    return Object.hashAll(nodes.map((n) {
      return Object.hash(
        n.key,
        n.anchor.latitude,
        n.anchor.longitude,
        n.alignment,
        n.margin,
        n.rotate,
        n.knownSize,
        n.priority,
        n.category,
        n.collisionMask,
        n.anchorRectPx,
        n.drawConnector,
      );
    }));
  }

  void _onMeasured(Key key, Size size) {
    final old = _sizeCache[key];
    if (old == null ||
        (old.width - size.width).abs() > 0.5 ||
        (old.height - size.height).abs() > 0.5) {
      _sizeCache[key] = size;
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalcAndRedraw());
    }
  }

  void _recalcAndRedraw() {
    if (!mounted) return;
    _recompute(force: true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cam = MapCamera.of(context);

    final measurers = <Widget>[];
    for (final n in _nodes) {
      if ((_sizeCache[n.key] ?? n.knownSize) == null &&
          n.measureBuilder != null) {
        measurers.add(Offstage(
          child: MeasureSize(
            onChange: (s) => _onMeasured(n.key, s),
            child: KeyedSubtree(
              key: ValueKey('${n.key}_measure'),
              child: n.measureBuilder!(context),
            ),
          ),
        ));
      }
    }

    final byKey = {for (final p in _placements) p.key: p};
    final children = <Widget>[];
    for (final n in _nodes) {
      final placement = byKey[n.key];
      if (placement == null) continue;
      final w = widget.builder(context, cam, n, placement);
      if (w != null) children.add(w);
    }

    final connectors = (widget.options.drawConnectors && _placements.isNotEmpty)
        ? Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConnectorPainter(
                  cam: cam,
                  nodes: _nodes,
                  placements: _placements,
                  color: widget.options.connectorColor,
                  strokeWidth: widget.options.connectorStrokeWidth,
                  defaultSize: widget.options.defaultSize,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Stack(children: [
      ...measurers,
      connectors,
      ...children,
    ]);
  }
}

/// Signature for the current view/camera state.
/// Used for caching and avoiding unnecessary recomputation.
class _ViewSig {
  const _ViewSig(
    this.z,
    this.r,
    this.w,
    this.h,
    this.lat,
    this.lng,
    this.optHash,
    this.nodesHash,
  );
  final double z, r, w, h, lat, lng;
  final int optHash;
  final int nodesHash;
  @override
  bool operator ==(Object o) =>
      o is _ViewSig &&
      (z - o.z).abs() < 1e-6 &&
      (r - o.r).abs() < 1e-6 &&
      (w - o.w).abs() < 0.5 &&
      (h - o.h).abs() < 0.5 &&
      (lat - o.lat).abs() < 1e-9 &&
      (lng - o.lng).abs() < 1e-9 &&
      optHash == o.optHash &&
      nodesHash == o.nodesHash;
  @override
  int get hashCode => Object.hash(z, r, w, h, lat, lng, optHash, nodesHash);
}
