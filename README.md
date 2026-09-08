<p align="center">
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/mkidv/flutter_map_interactive">
  </a>
  <a href="https://pub.dev/packages/flutter_map_interactive">
    <img alt="pub.dev" src="https://img.shields.io/pub/v/flutter_map_interactive?label=pub.dev">
  </a>
  <a href="https://pub.dev/packages/flutter_map_interactive/score">
    <img alt="pub points" src="https://img.shields.io/pub/points/flutter_map_interactive">
  </a>
  <a href="https://codecov.io/gh/mkidv/flutter_map_interactive">
    <img alt="codecov" src="https://codecov.io/gh/mkidv/flutter_map_interactive/graph/badge.svg">
  </a>
  <a href="https://github.com/mkidv/flutter_map_interactive/actions">
    <img alt="CI" src="https://github.com/mkidv/flutter_map_interactive/actions/workflows/dart.yml/badge.svg">
  </a>
</p>

# flutter_map_interactive

Interactive editing, collision avoidance, and state management for [flutter_map](https://pub.dev/packages/flutter_map).
A complete GIS interaction toolkit providing rich manipulation primitives: **Markers, Polylines, Image Overlays, Undo/Redo, and Collision Detection**.

<p align="center">
  <b>Tested</b> · <code>226/226 tests passing</code> · <code>flutter_map ^8.3.2</code>
</p>

## ✨ Features

- **Interactive Markers**: Tap, hover, long-press, drag-and-drop, popups, and animated contextual action menus (e.g. delete with confirmation).
- **Collision Detection & Avoidance**: High-performance spatial hashing (`SpatialHashGrid`), dynamic connector lines, and 5 pluggable layout strategies (`StickyGoldenFan`, `RadialFan`, `Orbit`, `Spiral`, `Nearest`).
- **Interactive Polylines**: Visual vertex editing (drag vertices, whole-polyline translation), selection outlines, and customizable handles.
- **Interactive Image Overlays**: 4-corner perspective manipulation (`QuadLatLng`), edge midpoint resizing/translation, rotation handles, and opacity control.
- **Unified State & History**: Transactional Undo/Redo with configurable merge delay (`mergeDelay`), save checkpoints, discard, abort, and `EntityDelta` change sets.
- **Reactive Event Stream**: Strongly typed sealed `InteractiveEvent` stream (`ItemSelected`, `DragUpdated`, `HistoryChanged`, etc.) for clean event-driven architectures.
- **Fine-Grained Rebuilds**: `ListenableSelector` and `CombinedSelector` to eliminate unnecessary widget tree repaints during drag or pan.
- **Pre-Built Controls**: Ready-to-use toolbar widgets (`EditModeToggleButton`, `EditModeUndoButton`, `EditModeRedoButton`, `MapCenterButton`).

## 📦 Install

```bash
flutter pub add flutter_map_interactive
```

Or add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_map: ^8.3.2
  flutter_map_interactive: ^0.1.0
  latlong2: ^0.9.1
```

## 🧭 API & Architecture

### High-Level Layers & Controllers

All entities share a unified controller architecture inheriting from `InteractiveController<T>`.

| Layer | Controller | Scope | Entity | Capabilities |
| :--- | :--- | :--- | :--- | :--- |
| **`InteractiveMarkerLayer`** | `MarkerController` | `InteractiveMarkerScope` | `InteractiveMarker` | Tap, hover, drag, popups, collision-avoiding labels, actions |
| **`InteractivePolylineLayer`** | `PolylineController` | `InteractivePolylineScope` | `InteractivePolyline` | Vertex drag handles, whole-line drag, selection styling |
| **`InteractiveOverlayLayer`** | `OverlayController` | `InteractiveOverlayScope` | `InteractiveOverlayImage` | 4 corners (`QuadLatLng`), 4 edges, rotation handle, opacity |

### Controller Cheat-Sheet

Every `InteractiveController<T>` provides:

- **CRUD**: `add(item)`, `addAll(items)`, `remove(key)`, `update(key, newItem)`, `clear()`
- **Selection**: `select(item)`, `deselect()`, `toggleSelect(item)`, `activeItem`, `activeKey`, `hasActive`
- **Edit Mode**: `startEditMode()`, `exitEditMode()`, `toggleEditMode()`, `isEditing`
- **History (Undo / Redo)**: `undo()`, `redo()`, `canUndo`, `canRedo`, `historyDepth`
- **Save Lifecycle**:
  - `save()`: Commits current state as the saved checkpoint
  - `discard()`: Reverts to the last saved checkpoint
  - `abort()`: Reverts completely to the initial state
  - `hasUnsavedChanges`: Checks if current state differs from the saved checkpoint
- **Spatial Index**: `spatialIndex` (`SpatialIndex<T>`) for fast bounding queries

### Events Cheat-Sheet

Consume the broadcast `controller.events` stream:

- **Interaction**: `ItemTapped`, `ItemSelected`, `ItemDeselected`, `ItemHovered`, `HoverCleared`, `ItemLongPressed`
- **Drag**: `DragStarted(item, origin)`, `DragUpdated(item, origin, current)`, `DragEnded(item, origin, finalPosition)`
- **History & Mode**: `HistoryChanged(current, canUndo, canRedo, historyDepth)`, `EditModeChanged(isEditing)`
- **CRUD**: `ItemAdded(item)`, `ItemRemoved(item)`, `ItemUpdated(oldItem, newItem)`

## 💡 Quick examples

### 1. Interactive Markers with Labels & Actions

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';
import 'package:latlong2/latlong.dart';

final markerController = MarkerController();

InteractiveMarkerLayer(
  markerController: markerController,
  markers: [
    InteractiveMarker(
      key: const ValueKey('paris'),
      point: const LatLng(48.8566, 2.3522),
      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
      options: [
        LabelMarkerOptions(
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Paris', style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
        PopupMarkerOptions(
          popup: const Card(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Capital of France'),
            ),
          ),
        ),
      ],
    ),
  ],
  options: InteractiveOptions(
    enabledGestures: const InteractiveEnabledGestures(
      tap: true,
      longPress: true,
      drag: true,
      hover: true,
    ),
    saveOnExit: true,
    onTap: (marker) => debugPrint('Tapped: ${marker.key}'),
    onSaved: (delta) => debugPrint('Saved: ${delta.updated.length} changes'),
  ),
  labelOptions: const LabelLayerOptions(
    strategy: StickyGoldenFanStrategy(hysteresisPx: 4.0),
    collision: CollisionOptions(
      avoidCollisions: true,
      drawConnectors: true,
    ),
  ),
  actionOptions: ActionLayerOptions(
    builder: (context, controller, marker) => MarkerActionMenu(
      actions: [
        TrashMarkerAction(
          onConfirm: (marker, {controller}) {
            if (marker.key != null) controller?.remove(marker.key!);
          },
        ),
      ],
    ),
  ),
)
```

### 2. Interactive Polylines (Vertex Editing & Drag)

```dart
final polylineController = PolylineController();

InteractivePolylineLayer(
  polylineController: polylineController,
  polylines: [
    InteractivePolyline(
      key: const ValueKey('track-1'),
      points: [
        LatLng(48.8584, 2.2945),
        LatLng(48.8606, 2.3376),
        LatLng(48.8530, 2.3499),
      ],
      color: Colors.blueAccent,
      strokeWidth: 4.0,
    ),
  ],
  handleOptions: const PolylineHandleOptions(
    size: 14.0,
    color: Colors.white,
    borderColor: Colors.blueAccent,
    activeColor: Colors.blueAccent,
    activeBorderColor: Colors.white,
    touchSizeFactor: 1.5,
  ),
)
```

### 3. Interactive Image Overlays (4 Corners, Edges & Rotation)

```dart
final overlayController = OverlayController();

InteractiveOverlayLayer(
  overlayController: overlayController,
  overlays: [
    InteractiveOverlayImage(
      key: const ValueKey('floorplan'),
      image: const AssetImage('assets/plan.png'),
      corners: const QuadLatLng(
        topLeft: LatLng(48.8590, 2.3470),
        topRight: LatLng(48.8590, 2.3530),
        bottomRight: LatLng(48.8540, 2.3530),
        bottomLeft: LatLng(48.8540, 2.3470),
      ),
      alpha: 200, // Opacity (0–255)
    ),
  ],
  handleOptions: const OverlayHandleOptions(
    size: 18.0,
    borderColor: Colors.teal,
    activeColor: Colors.tealAccent,
    connectorColor: Colors.teal,
  ),
)
```

### 4. Reactive Event Stream & Granular Selectors

```dart
// 1. Listen to events stream
final subscription = controller.events.listen((event) {
  switch (event) {
    case ItemSelected(item: final item):
      debugPrint('Selected: ${item.key}');
    case DragUpdated(item: final item, current: final pos):
      debugPrint('Dragging ${item.key} to $pos');
    case HistoryChanged(canUndo: final u, canRedo: final r):
      debugPrint('History updated: canUndo=$u, canRedo=$r');
    case EditModeChanged(isEditing: final editing):
      debugPrint('Edit mode: $editing');
    default:
      break;
  }
});

// 2. Fine-grained widget rebuilds
ListenableSelector<MarkerController, bool>(
  listenable: markerController,
  select: (c) => c.isEditing,
  builder: (context, isEditing) {
    return Chip(
      label: Text(isEditing ? 'Editing' : 'Viewing'),
      backgroundColor: isEditing ? Colors.amber : Colors.grey[200],
    );
  },
)
```

### 5. Ready-to-Use UI Toolbar

```dart
Card(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      EditModeToggleButton(controller: markerController),
      EditModeUndoButton(controller: markerController),
      EditModeRedoButton(controller: markerController),
      MapCenterButton(
        map: mapController,
        vsync: this,
        center: const LatLng(48.8566, 2.3522),
        zoom: 14.0,
        tooltip: 'Center Paris',
      ),
    ],
  ),
)
```

## ⚡ Collision Detection Strategies

When labels or pins overlap, `LabelLayerOptions` uses pluggable placement algorithms to lay out labels cleanly:

| Strategy | Behavior | Best Used For |
| :--- | :--- | :--- |
| **`StickyGoldenFanStrategy`** | *(Default)* Golden ratio spiral distribution with distance hysteresis | General use: completely eliminates label jitter during pan & zoom |
| **`RadialFanStrategy`** | Evenly distributes labels along a circular fan | Radial distribution around focal points |
| **`OrbitStrategy`** | Arranges labels in concentric circular orbits with increasing radii | Dense, clustered pin datasets |
| **`SpiralStrategy`** | Distributes labels along an Archimedean spiral outward | Very high density or arbitrary cluster layouts |
| **`NearestStrategy`** | Places labels at the nearest available free cell in the spatial grid | Strict grid alignment |

```dart
LabelLayerOptions(
  strategy: const StickyGoldenFanStrategy(hysteresisPx: 4.0),
  collision: const CollisionOptions(
    avoidCollisions: true,
    step: 16.0,
    maxRadius: 96.0,
    pad: 4.0,
    anchorPad: 4.0,
    drawConnectors: true,
    connectorColor: Color(0x66000000),
    connectorStrokeWidth: 1.5,
  ),
)
```

## ⚙️ Configuration Reference

### `InteractiveOptions<T>`

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `enabledGestures` | `InteractiveEnabledGestures` | `all()` | Enables/disables `tap`, `longPress`, `drag`, `hover` |
| `autoPanOnDrag` | `AutoPanOnDragOptions` | `enabled: true` | Automatically pans map viewport when dragging near edges |
| `moveOnTap` | `bool` | `false` | Pans map camera to tapped entity |
| `centerOnTap` | `bool` | `true` | Centers camera on tapped entity |
| `saveOnExit` | `bool` | `true` | Commits changes to saved checkpoint upon exiting edit mode |
| `autoSave` | `bool` | `false` | Automatically saves changes during edit after `autoSaveDelay` |
| `autoSaveDelay` | `Duration` | `700ms` | Debounce delay for `autoSave` |
| `mergeDelay` | `Duration` | `150ms` | Window to merge rapid drag updates into a single undo operation |
| `onTap` | `InteractiveCallback<T>?` | `null` | Invoked on entity tap |
| `onLongPress` | `InteractiveCallback<T>?` | `null` | Invoked on entity long press |
| `onHovered` | `InteractiveCallback<T>?` | `null` | Invoked on pointer hover enter/exit |
| `onSaved` | `OnEntityDeltaCallback<T>?`| `null` | Invoked when changes are saved (provides added, updated, removed) |
| `onEditModeChanged`| `ValueChanged<bool>?` | `null` | Invoked when entering or exiting edit mode |

## 🧪 Testing

This repo ships with a comprehensive test suite covering collision detection, transactions, quad geometry, and gestures:

```bash
flutter test
```

## License

MIT
