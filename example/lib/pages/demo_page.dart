import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/example_data.dart';
import '../widgets/control_panel.dart';

enum DemoScene { markers, polylines, overlays }

class DemoPage extends StatefulWidget {
  const DemoPage({super.key, this.tileProvider});

  /// Allows widget tests to exercise the demo without requesting map tiles.
  final TileProvider? tileProvider;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _map = MapController();
  final _mapKey = GlobalKey();
  final _markers = MarkerController();
  final _polylines = PolylineController();
  final _overlays = OverlayController();
  final _subscriptions = <StreamSubscription<InteractiveEvent<Object>>>[];
  late final List<Marker> _initialMarkers;
  late final List<InteractivePolyline> _initialPolylines;
  late final List<InteractiveOverlayImage> _initialOverlays;
  final _activity =
      ValueNotifier<String>('Choose a scene, then select an item.');
  DemoScene _scene = DemoScene.markers;
  bool _avoidCollisions = true;
  bool _connectors = true;
  bool _debug = false;
  bool _dense = true;
  bool _labels = true;
  bool _ready = false;
  double _opacity = 0.65;
  int _strategy = 0;
  int _nextId = 0;

  static const _strategies = <String, CollisionStrategy>{
    'Sticky golden fan': StickyGoldenFanStrategy(),
    'Orbit': OrbitStrategy(),
    'Spiral': SnapBackSpiralStrategy(),
    'Radial fan': RadialFanStrategy(),
    'Nearest': StickyNearestStrategy(),
  };

  InteractiveController<Object> get _controller => switch (_scene) {
        DemoScene.markers => _markers,
        DemoScene.polylines => _polylines,
        DemoScene.overlays => _overlays,
      };

  @override
  void initState() {
    super.initState();
    _initialMarkers = _markerData(dense: true);
    _initialPolylines = ExampleData.initialPolylines;
    _initialOverlays = [_overlay('floor-plan', ExampleData.latLngStart)];
    // Layers initialise during map layout. Attach sibling toolbar listeners
    // after their initial notifications, once the first frame is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
    for (final controller in <InteractiveController<Object>>[
      _markers,
      _polylines,
      _overlays,
    ]) {
      _subscriptions.add(controller.events.listen((event) {
        // Drag frames can arrive at pointer frequency; keep the log inexpensive.
        if (event is DragUpdated ||
            event is HistoryChanged ||
            event is ItemHovered ||
            event is HoverCleared) {
          return;
        }
        _activity.value = switch (event) {
          ItemAdded() => 'Item added. Try Undo to remove it again.',
          ItemRemoved() => 'Item deleted. Undo restores it.',
          ItemUpdated() => 'Item updated.',
          ItemSelected() => 'Item selected. Enable editing to change it.',
          ItemDeselected() => 'Selection cleared.',
          DragStarted() => 'Dragging…',
          DragEnded() => 'Drag complete. Try Undo to restore its position.',
          EditModeChanged() => 'Edit mode changed.',
          _ => 'Selection updated.',
        };
      }));
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _markers.dispose();
    _polylines.dispose();
    _overlays.dispose();
    _map.dispose();
    _activity.dispose();
    super.dispose();
  }

  List<Marker> _markerData({required bool dense}) => (dense
          ? ExampleData.denseMarkerLocations(
              rows: 4, cols: 4, latStep: 0.00018, lngStep: 0.00024)
          : ExampleData.markerLocations)
      .map((entry) => _marker(entry.id, entry.point))
      .toList();

  InteractiveMarker _marker(String id, LatLng point) => InteractiveMarker(
        key: ValueKey(id),
        point: point,
        width: 28,
        height: 28,
        child: const Icon(Icons.location_on, color: Colors.indigo, size: 28),
        options: [
          LabelMarkerOptions(
            label: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(id, style: const TextStyle(color: Colors.white)),
            ),
          ),
          PopupMarkerOptions(
            popup: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Marker $id\nEnable editing to drag this pin.'),
              ),
            ),
          ),
        ],
      );

  InteractiveOverlayImage _overlay(String id, LatLng center) {
    const d = 0.003;
    return InteractiveOverlayImage(
      key: ValueKey(id),
      image: const AssetImage('assets/plan.png'),
      alpha: (_opacity * 255).round(),
      corners: QuadLatLng(
        topLeft: LatLng(center.latitude + d, center.longitude - d),
        topRight: LatLng(center.latitude + d, center.longitude + d),
        bottomRight: LatLng(center.latitude - d, center.longitude + d),
        bottomLeft: LatLng(center.latitude - d, center.longitude - d),
      ),
    );
  }

  void _centerScene() {
    _map.move(
      _scene == DemoScene.polylines
          ? const LatLng(48.124, -1.680)
          : ExampleData.latLngStart,
      _scene == DemoScene.markers && _dense ? 17 : 14,
    );
  }

  void _chooseScene(DemoScene scene) {
    setState(() => _scene = scene);
    _centerScene();
  }

  void _add() {
    _controller.startEditMode();
    final center = _map.camera.center;
    final id = 'new-${++_nextId}';
    switch (_scene) {
      case DemoScene.markers:
        final item = _marker(id, center);
        _markers.add(item);
        _markers.select(item);
      case DemoScene.polylines:
        final item = InteractivePolyline(
          key: ValueKey(id),
          points: [
            LatLng(center.latitude - .002, center.longitude - .003),
            LatLng(center.latitude + .002, center.longitude),
            LatLng(center.latitude - .002, center.longitude + .003),
          ],
          color: Colors.indigo,
          strokeWidth: 5,
        );
        _polylines.add(item);
        _polylines.select(item);
      case DemoScene.overlays:
        final item = _overlay(id, center);
        _overlays.add(item);
        _overlays.select(item);
    }
  }

  void _reset() {
    switch (_scene) {
      case DemoScene.markers:
        _markers.setMarkers(_markerData(dense: _dense), resetHistory: true);
      case DemoScene.polylines:
        _polylines.setPolylines(_initialPolylines, resetHistory: true);
      case DemoScene.overlays:
        _overlays.setOverlays(
          [_overlay('floor-plan', ExampleData.latLngStart)],
          resetHistory: true,
        );
    }
    _controller.deselect();
    _centerScene();
    _activity.value = 'Scene reset. History cleared.';
  }

  void _setOpacity(double value) {
    setState(() => _opacity = value);
    for (final overlay in List<InteractiveOverlayImage>.of(_overlays.current)) {
      _overlays.update(
          overlay.key!, overlay.copyWith(alpha: (value * 255).round()),
          merge: true);
    }
  }

  Future<void> _open(String url) async {
    if (!await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank') &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open $url in your browser.')),
      );
    }
  }

  Widget _mapView() => FlutterMap(
        key: _mapKey,
        mapController: _map,
        options: const MapOptions(
          initialCenter: ExampleData.latLngStart,
          initialZoom: 17,
        ),
        children: [
          TileLayer(
            tileProvider: widget.tileProvider,
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.mki.flutter_map_interactive.example',
          ),
          // Keep all layer states mounted: scene changes must not reset history.
          Offstage(
            offstage: _scene != DemoScene.overlays,
            child: InteractiveOverlayLayer(
              overlays: _initialOverlays,
              overlayController: _overlays,
            ),
          ),
          Offstage(
            offstage: _scene != DemoScene.polylines,
            child: InteractivePolylineLayer(
              polylines: _initialPolylines,
              polylineController: _polylines,
              debug: _debug,
            ),
          ),
          Offstage(
            offstage: _scene != DemoScene.markers,
            child: InteractiveMarkerLayer(
              markers: _initialMarkers,
              markerController: _markers,
              options: const InteractiveOptions(centerOnTap: false),
              labelOptions: _labels
                  ? LabelLayerOptions(
                      strategy: _strategies.values.elementAt(_strategy),
                      collision: CollisionOptions(
                        maxRadius: 180,
                        step: 12,
                        pad: 3,
                        avoidCollisions: _avoidCollisions,
                        drawConnectors: _connectors,
                      ),
                    )
                  : null,
              popupOptions: const PopupLayerOptions(),
              actionOptions: ActionLayerOptions(
                builder: (context, controller, marker) =>
                    const MarkerActionMenu(
                  actions: [TrashMarkerAction()],
                ),
              ),
              debug: _debug,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: TextButton(
                onPressed: () =>
                    _open('https://www.openstreetmap.org/copyright'),
                child: const Text('© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
        ],
      );

  Widget _controls() => !_ready
      ? const SizedBox.shrink()
      : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Explore the package',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<DemoScene>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DemoScene.markers, label: Text('Pins')),
                ButtonSegment(value: DemoScene.polylines, label: Text('Lines')),
                ButtonSegment(value: DemoScene.overlays, label: Text('Images')),
              ],
              selected: {_scene},
              onSelectionChanged: (value) => _chooseScene(value.first),
            ),
            const SizedBox(height: 16),
            Text(
                switch (_scene) {
                  DemoScene.markers => 'Collision-aware labels',
                  DemoScene.polylines => 'Edit a route',
                  DemoScene.overlays => 'Position a floor plan',
                },
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(switch (_scene) {
              DemoScene.markers =>
                'Compare collision strategies, pan and zoom. '
                    'Tap a pin for its popup. Enable editing to drag it.',
              DemoScene.polylines => 'Select the line and enable editing. Drag '
                  'a vertex to reshape it, or drag the line to move it.',
              DemoScene.overlays => 'Select the image and enable editing. Drag '
                  'corners, edges and the rotation handle to align the plan.',
            }),
            const SizedBox(height: 16),
            DemoControls(
              controller: _controller,
              onAdd: _add,
              onReset: _reset,
              onCenter: _centerScene,
              onSaved: () => _activity.value = 'Checkpoint saved in memory.',
            ),
            const Divider(height: 32),
            if (_scene == DemoScene.markers) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Avoid label collisions'),
                value: _avoidCollisions,
                onChanged: (value) => setState(() => _avoidCollisions = value),
              ),
              DropdownButtonFormField<int>(
                initialValue: _strategy,
                decoration:
                    const InputDecoration(labelText: 'Placement strategy'),
                items: [
                  for (var i = 0; i < _strategies.length; i++)
                    DropdownMenuItem(
                        value: i, child: Text(_strategies.keys.elementAt(i))),
                ],
                onChanged: (value) => setState(() => _strategy = value!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Labels'),
                value: _labels,
                onChanged: (value) => setState(() => _labels = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Connector lines'),
                value: _connectors,
                onChanged: (value) => setState(() => _connectors = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dense dataset (16 pins)'),
                subtitle: const Text('Changing the dataset resets this scene.'),
                value: _dense,
                onChanged: (value) {
                  setState(() => _dense = value);
                  _reset();
                },
              ),
            ],
            if (_scene == DemoScene.overlays) ...[
              Text('Image opacity: ${(_opacity * 100).round()}%'),
              Slider(value: _opacity, min: .1, onChanged: _setOpacity),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show hitboxes'),
              value: _debug,
              onChanged: (value) => setState(() => _debug = value),
            ),
            const Divider(height: 32),
            Text('Latest interaction',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: _activity,
              builder: (context, value, child) => Text(value),
            ),
            const SizedBox(height: 16),
            const Text(
                'Changes live in this tab only. Save creates an in-memory '
                'checkpoint; reloading the page starts a fresh demo.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                    onPressed: () => _open(
                        'https://pub.dev/packages/flutter_map_interactive'),
                    child: const Text('pub.dev')),
                TextButton(
                    onPressed: () => _open(
                        'https://github.com/mkidv/flutter_map_interactive'),
                    child: const Text('Source on GitHub')),
              ],
            ),
          ],
        );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('flutter_map_interactive'),
          actions: [
            IconButton(
              tooltip: 'Reset current scene',
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return Row(children: [
                Expanded(child: _mapView()),
                const VerticalDivider(width: 1),
                SizedBox(width: 340, child: _controls()),
              ]);
            }
            return Column(children: [
              Expanded(child: _mapView()),
              const Divider(height: 1),
              SizedBox(
                height: (constraints.maxHeight * .44).clamp(0.0, 340.0),
                child: _controls(),
              ),
            ]);
          },
        ),
      );
}
