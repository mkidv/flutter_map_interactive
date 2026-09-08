import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:latlong2/latlong.dart';

import '../data/example_data.dart';
import '../widgets/control_panel.dart';
import '../widgets/layer_settings.dart';

enum _PanProfile { mapOnly, markersOnly, labels, full }

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});
  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> with TickerProviderStateMixin {
  final MapController _map = MapController();

  late final MarkerController _inter;
  late final OverlayController _interOverlay;
  late final PolylineController _interPolyline;

  // Settings state
  bool _debugHitbox = false;
  bool _collisionAvoidance = false;
  double _overlayAlpha = 0.8;
  bool _showSettings = false;
  bool _showMarkersLayer = true;
  bool _showMarkerLabels = true;
  bool _showMarkerConnectors = true;
  bool _showPolylineLayer = true;
  bool _showOverlayLayer = true;
  bool _denseMarkers = false;

  // Gestures
  bool _gTap = true, _gMoveOnTap = false;
  final bool _gLong = true;
  final bool _gDrag = true;

  final _markers = <Marker>[];
  final _polylines = <InteractivePolyline>[];

  @override
  void initState() {
    super.initState();

    _inter = MarkerController();
    _interOverlay = OverlayController();
    _interPolyline = PolylineController();

    _rebuildMarkers();
    _polylines.addAll(ExampleData.initialPolylines);
  }

  @override
  void dispose() {
    _inter.dispose();
    _interOverlay.dispose();
    _interPolyline.dispose();
    super.dispose();
  }

  InteractiveMarker _mk(String id, LatLng p) => InteractiveMarker(
          key: ValueKey(id),
          point: p,
          width: 30,
          height: 30,
          rotate: true,
          alignment: Alignment.center,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child:
                const Icon(Icons.location_on, size: 20, color: Colors.indigo),
          ),
          options: [
            LabelMarkerOptions(
              label: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  id.substring(id.length > 4 ? id.length - 4 : 0),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              rotate: true,
            ),
          ]);

  void _rebuildMarkers() {
    final source = _denseMarkers
        ? ExampleData.denseMarkerLocations()
        : ExampleData.markerLocations;
    _markers
      ..clear()
      ..addAll(source.map((e) => _mk(e.id, e.point)));
  }

  void _setDenseMarkers(bool value) {
    setState(() {
      _denseMarkers = value;
      _rebuildMarkers();
    });
  }

  void _applyPanProfile(_PanProfile profile) {
    setState(() {
      switch (profile) {
        case _PanProfile.mapOnly:
          _showMarkersLayer = false;
          _showMarkerLabels = false;
          _showMarkerConnectors = false;
          _showPolylineLayer = false;
          _showOverlayLayer = false;
        case _PanProfile.markersOnly:
          _showMarkersLayer = true;
          _showMarkerLabels = false;
          _showMarkerConnectors = false;
          _showPolylineLayer = false;
          _showOverlayLayer = false;
        case _PanProfile.labels:
          _showMarkersLayer = true;
          _showMarkerLabels = true;
          _showMarkerConnectors = false;
          _showPolylineLayer = false;
          _showOverlayLayer = false;
        case _PanProfile.full:
          _showMarkersLayer = true;
          _showMarkerLabels = true;
          _showMarkerConnectors = true;
          _showPolylineLayer = true;
          _showOverlayLayer = true;
      }
    });
  }

  void _addAtCenter() {
    if (!_inter.isEditing) _inter.startEditMode();
    final c = _map.camera.center;
    final id = 'M${DateTime.now().millisecondsSinceEpoch % 100000}';
    _inter.add(_mk(id, c));
  }

  void _clearAll() {
    final key = _inter.activeKey;
    if (key != null) {
      _inter.remove(key);
      _inter.remove(key);
      _inter.deselect();
    }
  }

  void _addPolyline() {
    if (!_interPolyline.isEditing) _interPolyline.startEditMode();
    final c = _map.camera.center;
    // Create a zigzag line around center
    final points = [
      LatLng(c.latitude - 0.005, c.longitude - 0.005),
      LatLng(c.latitude + 0.005, c.longitude),
      LatLng(c.latitude - 0.005, c.longitude + 0.005),
    ];

    final id = 'P${DateTime.now().millisecondsSinceEpoch % 100000}';
    _interPolyline.add(InteractivePolyline(
      key: ValueKey(id),
      points: points,
      color: Colors.blueAccent,
      strokeWidth: 4.0,
    ));
  }

  void _clearPolylines() {
    final key = _interPolyline.activeKey;
    if (key != null) {
      _interPolyline.remove(key);
      _interPolyline.remove(key);
      _interPolyline.deselect();
    }
  }

  void _addOverlay() {
    if (!_interOverlay.isEditing) _interOverlay.startEditMode();
    final c = _map.camera.center;
    final id = 'O${DateTime.now().millisecondsSinceEpoch % 100000}';

    // Create a square overlay around center
    const delta = 0.005;
    final tl = LatLng(c.latitude + delta, c.longitude - delta);
    final tr = LatLng(c.latitude + delta, c.longitude + delta);
    final br = LatLng(c.latitude - delta, c.longitude + delta);
    final bl = LatLng(c.latitude - delta, c.longitude - delta);

    _interOverlay.add(InteractiveOverlayImage(
      key: ValueKey(id),
      image: const AssetImage('assets/plan.png'),
      corners: QuadLatLng(
          topLeft: tl, topRight: tr, bottomRight: br, bottomLeft: bl),
      alpha: 200,
    ));
  }

  void _clearOverlays() {
    final key = _interOverlay.activeKey;
    if (key != null) {
      _interOverlay.remove(key);
      _interOverlay.remove(key);
      _interOverlay.deselect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gestures = InteractiveEnabledGestures(
      tap: _gTap,
      longPress: _gLong,
      drag: _gDrag,
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: const MapOptions(
              initialCenter: LatLng(48.111, -1.680),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'example.enhanced_marker',
              ),
              if (_showOverlayLayer)
                InteractiveOverlayLayer(
                  overlayController: _interOverlay,
                  overlays: [
                    InteractiveOverlayImage(
                      key: const ValueKey('image1'),
                      image: const AssetImage('assets/plan.png'),
                      corners: const QuadLatLng(
                        topLeft: ExampleData.overlay1Tl,
                        topRight: ExampleData.overlay1Tr,
                        bottomRight: ExampleData.overlay1Br,
                        bottomLeft: ExampleData.overlay1Bl,
                      ),
                      alpha: (_overlayAlpha * 255.0).toInt(),
                    ),
                    InteractiveOverlayImage(
                      key: const ValueKey('image2'),
                      image: const AssetImage('assets/plan.png'),
                      corners: const QuadLatLng(
                        topLeft: ExampleData.overlay2Tl,
                        topRight: ExampleData.overlay2Tr,
                        bottomRight: ExampleData.overlay2Br,
                        bottomLeft: ExampleData.overlay2Bl,
                      ),
                      alpha: (_overlayAlpha * 255.0).toInt(),
                    ),
                  ],
                ),
              if (_showPolylineLayer)
                InteractivePolylineLayer(
                  polylines: _polylines,
                  polylineController: _interPolyline,
                  debug: _debugHitbox,
                ),
              if (_showMarkersLayer)
                InteractiveMarkerLayer(
                  markerController: _inter,
                  markers: _markers,
                  options: InteractiveOptions(
                    saveOnExit: true,
                    onSaved: (delta) {
                      if (mounted && delta.hasChanged) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved !')),
                        );
                      }
                    },
                    enabledGestures: gestures,
                    moveOnTap: _gMoveOnTap,
                  ),
                  markerOptions: InteractiveLayerOptions(
                    activeBuilder: (context, controller, marker) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.pink, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withAlpha(50),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child:
                            const Icon(Icons.location_on, color: Colors.pink),
                      );
                    },
                  ),
                  labelOptions: _showMarkerLabels
                      ? LabelLayerOptions(
                          collision: CollisionOptions(
                            avoidCollisions: _collisionAvoidance,
                            drawConnectors: _showMarkerConnectors,
                          ),
                        )
                      : null,
                  actionOptions: ActionLayerOptions(
                      builder: (context, controller, marker) => _MarkerActions(
                            onDelete: () {
                              final key = _inter.activeKey;
                              if (key != null) _inter.remove(key);
                              _inter.deselect();
                            },
                          )),
                  debug: _debugHitbox,
                ),
            ],
          ),

          // --- UI Overlays ---

          // Top Left Title
          Positioned(
            top: 40,
            left: 20,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text('Interactive Marker',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // Right Toolbar
          Positioned(
            top: 40,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Toolbox(
                  markerController: _inter,
                  polylineController: _interPolyline,
                  overlayController: _interOverlay,
                  onAddMarker: _addAtCenter,
                  onAddPolyline: _addPolyline,
                  onAddOverlay: _addOverlay,
                  onClearMarkers: _clearAll,
                  onClearPolylines: _clearPolylines,
                  onClearOverlays: _clearOverlays,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  child: Icon(
                      _showSettings ? Icons.settings : Icons.settings_outlined,
                      color: Colors.black87),
                  onPressed: () =>
                      setState(() => _showSettings = !_showSettings),
                ),
              ],
            ),
          ),

          // Settings Panel
          if (_showSettings)
            Positioned(
              top: 150,
              right: 80,
              child: LayerSettingsPanel(
                title: 'Layer Settings',
                onClose: () => setState(() => _showSettings = false),
                child: Column(
                  children: [
                    ToggleSetting(
                      label: 'Debug Hitboxes',
                      value: _debugHitbox,
                      onChanged: (v) => setState(() => _debugHitbox = v),
                    ),
                    ToggleSetting(
                      label: 'Collision Avoidance',
                      value: _collisionAvoidance,
                      onChanged: (v) => setState(() => _collisionAvoidance = v),
                    ),
                    const SizedBox(height: 8),
                    Text('Pan Profiling',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Map only'),
                          onPressed: () => _applyPanProfile(_PanProfile.mapOnly),
                        ),
                        ActionChip(
                          label: const Text('Markers'),
                          onPressed: () =>
                              _applyPanProfile(_PanProfile.markersOnly),
                        ),
                        ActionChip(
                          label: const Text('Labels'),
                          onPressed: () => _applyPanProfile(_PanProfile.labels),
                        ),
                        ActionChip(
                          label: const Text('Full'),
                          onPressed: () => _applyPanProfile(_PanProfile.full),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Layer Visibility',
                        style: Theme.of(context).textTheme.labelLarge),
                    ToggleSetting(
                      label: 'Markers Layer',
                      value: _showMarkersLayer,
                      onChanged: (v) => setState(() => _showMarkersLayer = v),
                    ),
                    ToggleSetting(
                      label: 'Marker Labels',
                      value: _showMarkerLabels,
                      onChanged: (v) => setState(() => _showMarkerLabels = v),
                    ),
                    ToggleSetting(
                      label: 'Label Connectors',
                      value: _showMarkerConnectors,
                      onChanged: (v) =>
                          setState(() => _showMarkerConnectors = v),
                    ),
                    ToggleSetting(
                      label: 'Polylines Layer',
                      value: _showPolylineLayer,
                      onChanged: (v) => setState(() => _showPolylineLayer = v),
                    ),
                    ToggleSetting(
                      label: 'Overlays Layer',
                      value: _showOverlayLayer,
                      onChanged: (v) => setState(() => _showOverlayLayer = v),
                    ),
                    ToggleSetting(
                      label: 'Dense Markers',
                      value: _denseMarkers,
                      onChanged: _setDenseMarkers,
                    ),
                    const SizedBox(height: 8),
                    SliderSetting(
                      label: 'Overlay Alpha',
                      value: _overlayAlpha,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (v) => setState(() => _overlayAlpha = v),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Gestures',
                        style: Theme.of(context).textTheme.labelLarge),
                    ToggleSetting(
                      label: 'Tap to Interact',
                      value: _gTap,
                      onChanged: (v) => setState(() => _gTap = v),
                    ),
                    ToggleSetting(
                      label: 'Move on Tap',
                      value: _gMoveOnTap,
                      onChanged: (v) => setState(() => _gMoveOnTap = v),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkerActions extends StatelessWidget {
  final VoidCallback onDelete;
  const _MarkerActions({required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return MarkerActionMenu(
      actions: [
        SimpleMarkerAction(
          icon: const Icon(Icons.edit),
          onPressed: (marker, {MarkerController? controller}) =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Edit action!'))),
        ),
        const TrashMarkerAction(),
      ],
    );
  }
}
