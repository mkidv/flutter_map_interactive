## 0.2.0

This release focuses on the interactive example and documentation. The public package API is unchanged.

* Rebuild the interactive example around marker, polyline, and image overlay scenes with adaptive desktop and mobile controls.
* Preserve scene edits and history across scene switches, settings changes, and layout changes.
* Add collision strategy comparison, marker popups, checkpoint/discard controls, reset, and interaction feedback.
* Add regression tests for the demo and an automated GitHub Pages deployment workflow.
* Link the browser demo from the README and document local development and deployment.

## 0.1.1

* Update `latlong2` to `^0.10.1` and `meta` to `^1.19.0`.
* Update the example and installation instructions to use the new dependency versions.
* Exclude generated build and platform directories from example analysis.

## 0.1.0

* Initial release of `flutter_map_interactive`.
* **Interactive Markers**:
  - `InteractiveMarkerLayer` with collision detection strategies (`StickyGoldenFanStrategy`, `OrbitStrategy`, `SpiralStrategy`, `RadialFanStrategy`, `NearestStrategy`).
  - Spatial indexing (`SpatialIndex`) for fast hit testing on large marker datasets.
  - Interactive states: tap, hover, long press, drag-and-drop, dynamic label placement, popups, and contextual action menus (`MarkerActionMenu`, `TrashMarkerAction`, `ExpandableMarkerAction`).
* **Interactive Polylines**:
  - `InteractivePolylineLayer` with vertex editing handles, whole-shape drag, and `PolylineHandleOptions`.
* **Interactive Image Overlays**:
  - `InteractiveOverlayLayer` with 4-corner repositioning (`QuadLatLng`), edge translation, and rotation handles.
  - Padded quad hit-testing for easy selection and manipulation.
* **Unified State & History Management**:
  - `InteractiveController<T>` with concrete implementations (`MarkerController`, `PolylineController`, `OverlayController`).
  - Full transactional undo/redo history with configurable merge delay.
  - Save, discard, and abort lifecycle states.
  - Reactive event stream (`InteractiveEvent`) emitting interaction, CRUD, drag, and history events.
* **Reactive Widgets & Pre-built Controls**:
  - `ListenableSelector` & `CombinedSelector` for fine-grained rebuild optimization.
  - `EditModeToggleButton`, `EditModeUndoButton`, `EditModeRedoButton`, and `MapCenterButton`.
  - Scoped inherited widgets (`InteractiveMarkerScope`, `InteractivePolylineScope`, `InteractiveOverlayScope`).
