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
