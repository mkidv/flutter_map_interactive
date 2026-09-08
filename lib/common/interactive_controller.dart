import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_interactive/common/entity_delta.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/events.dart';
import 'package:flutter_map_interactive/common/history/history_manager.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/mixins/crud_mixin.dart';
import 'package:flutter_map_interactive/common/mixins/drag_mixin.dart';
import 'package:flutter_map_interactive/common/mixins/interaction_mixin.dart';
import 'package:flutter_map_interactive/common/mixins/transaction_mixin.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/spatial_index.dart';

/// A unified base controller for managing interactive entities [T].
///
/// Combines:
/// - **Transaction Management**: Undo/Redo/Merge via [TransactionMixin].
/// - **CRUD Operations**: Add/Remove/Update via [CRUDMixin].
/// - **Interaction Management**: Selection, Hover, Long Press via [InteractionMixin].
/// - **Drag Management**: Drag operations via [DragMixin].
/// - **Logic Delegation**: Uses [EntityLogic] for type-specific operations.
abstract class InteractiveController<T> extends ChangeNotifier
    with TransactionMixin<T>, CRUDMixin<T>, InteractionMixin<T>, DragMixin<T> {
  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  InteractiveController() {
    _transactions.addListener(_handleHistoryChanged);
    _transactions.setMergeDelay(_options.mergeDelay);
  }
  final HistoryManager<T> _transactions = HistoryManager<T>();
  InteractiveOptions<T> _options = const InteractiveOptions();
  Timer? _autoSaveTimer;

  /// Spatial index for fast range queries.
  final SpatialIndex<T> spatialIndex = SpatialIndex<T>();

  /// Flag indicating if spatial index needs rebuilding.
  bool _indexDirty = false;

  final Map<Key, T> _itemCache = {};

  /// Stream controller for emitting interaction events.
  final StreamController<InteractiveEvent<T>> _eventController =
      StreamController<InteractiveEvent<T>>.broadcast();

  /// Stream of all interactive events.
  ///
  /// Listen to this stream for reactive programming patterns:
  /// ```dart
  /// controller.events.listen((event) {
  ///   switch (event) {
  ///     case ItemTapped(item: var m): print('Tapped: $m');
  ///     case HistoryChanged(): print('History updated');
  ///   }
  /// });
  /// ```
  Stream<InteractiveEvent<T>> get events => _eventController.stream;

  @override
  late final EntityLogic<T> logic;

  // ===========================================================================
  // MIXIN REQUIREMENTS
  // ===========================================================================

  @override
  HistoryManager<T> get history => _transactions;

  @override
  void performOp(Op<T> op, {bool merge = false}) {
    _transactions.commit(op, merge: merge, notify: true);
    _refreshReferences();
  }

  // ===========================================================================
  // STATE ACCESS
  // ===========================================================================

  @protected
  List<T> get internalInitial => _transactions.readOnlyInitial;
  @protected
  List<T> get internalCurrent => _transactions.current;
  @protected
  List<T> get internalSaved => _transactions.readOnlySaved;

  int get version => _transactions.version;

  List<T> get current => UnmodifiableListView(internalCurrent);

  @override
  T? findByKey(Key key) => _itemCache[key];

  // ===========================================================================
  // INDEX MANAGEMENT
  // ===========================================================================

  void _rebuildSpatialIndex() {
    spatialIndex.clear();
    for (final item in internalCurrent) {
      final key = logic.getItemKey(item);
      if (key != null) {
        spatialIndex.add(key, item, logic.getBounds(item));
      }
    }
    _indexDirty = false;
  }

  /// Ensures spatial index is up-to-date before querying.
  /// Call this before any spatial operations.
  void ensureIndexFresh() {
    if (_indexDirty) {
      _rebuildSpatialIndex();
    }
  }

  // ===========================================================================
  // INTERACTION STATE FORWARDING
  // ===========================================================================

  T? get activeItem =>
      activeKeys.isNotEmpty ? findByKey(activeKeys.first) : null;
  T? get longPressedItem =>
      longPressedKeys.isNotEmpty ? findByKey(longPressedKeys.first) : null;

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  bool _editMode = false;
  ValueChanged<bool>? _onEditModeChanged;

  bool get isEditing => _editMode;
  bool get hasUnsavedChanges => _hasUnsavedChanges();

  @protected
  InteractiveOptions<T> get options => _options;

  @protected
  void setEditModeCallback(ValueChanged<bool>? callback) {
    _onEditModeChanged = callback;
  }

  void startEditMode() {
    if (_editMode) return;
    _editMode = true;
    _onEditModeChanged?.call(true);
    _emit(EditModeChanged(true));
    notifyListeners();
  }

  void exitEditMode() {
    if (!_editMode) return;
    _cancelAutoSave();
    if (_options.saveOnExit && _hasUnsavedChanges()) {
      save();
    }
    _editMode = false;
    _onEditModeChanged?.call(false);
    _emit(EditModeChanged(false));
    deselect();
    notifyListeners();
  }

  void setEditMode(bool enable) => enable ? startEditMode() : exitEditMode();
  void toggleEditMode() => setEditMode(!isEditing);

  // ===========================================================================
  // CALLBACK CONFIGURATION
  // ===========================================================================

  ValueChanged<T>? _onAddedCallback;
  ValueChanged<T>? _onRemovedCallback;
  ValueChanged<T>? _onUpdatedCallback;
  ValueChanged<EntityDelta<T>>? _onSavedCallback;

  ValueChanged<T>? _onTapCallback;
  ValueChanged<T>? _onActiveCallback;
  ValueChanged<T>? _onHoverCallback;
  ValueChanged<T>? _onLongPressCallback;

  @override
  ValueChanged<T>? get onAddedCallback => _onAddedCallback;
  @override
  ValueChanged<T>? get onRemovedCallback => _onRemovedCallback;
  @override
  ValueChanged<T>? get onUpdatedCallback => _onUpdatedCallback;

  @override
  ValueChanged<T>? get onTapCallback => _onTapCallback;
  @override
  ValueChanged<T>? get onActiveCallback => _onActiveCallback;
  @override
  ValueChanged<T>? get onHoverCallback => _onHoverCallback;
  @override
  ValueChanged<T>? get onLongPressCallback => _onLongPressCallback;

  @protected
  void setCallbacks({
    ValueChanged<T>? onAdded,
    ValueChanged<T>? onRemoved,
    ValueChanged<T>? onUpdated,
    ValueChanged<EntityDelta<T>>? onSaved,
    ValueChanged<T>? onTap,
    ValueChanged<T>? onActive,
    ValueChanged<T>? onHover,
    ValueChanged<T>? onLongPress,
  }) {
    _onAddedCallback = onAdded;
    _onRemovedCallback = onRemoved;
    _onUpdatedCallback = onUpdated;
    _onSavedCallback = onSaved;
    _onTapCallback = onTap;
    _onActiveCallback = onActive;
    _onHoverCallback = onHover;
    _onLongPressCallback = onLongPress;
  }

  /// Updates the controller configuration options.
  void setOptions(InteractiveOptions<T> options) {
    _options = options;
    _transactions.setMergeDelay(options.mergeDelay);
    setEditModeCallback(options.onEditModeChanged);

    // Update generic callbacks
    setCallbacks(
      onAdded: options.onAdded,
      onRemoved: options.onRemoved,
      onUpdated: options.onUpdated,
      onSaved: (delta) => options.onSaved?.call(delta),
      onTap: options.onTap,
      onActive: options.onActive,
      onHover: options.onHovered,
      onLongPress: options.onLongPress,
    );
    // Note: Specialized fields like mergeDelay or saveOnExit are accessed via specific controller implementation
    // usually. Or should InteractiveController hold the reference?
    // For now, subclasses hold the reference. But generic configuration injection is useful here.
  }

  @override
  void dispose() {
    _cancelAutoSave();
    _transactions.removeListener(_handleHistoryChanged);
    _transactions.dispose();
    _eventController.close();
    disposeDrag();
    super.dispose();
  }

  @override
  void undo() {
    if (!canUndo) return;
    super.undo();
    _refreshReferences();
    scheduleAutoSave();
  }

  @override
  void redo() {
    if (!canRedo) return;
    super.redo();
    _refreshReferences();
    scheduleAutoSave();
  }

  @override
  void setItems(List<T> items, {required bool resetHistory}) {
    super.setItems(items, resetHistory: resetHistory);
    _refreshReferences();
  }

  // ===========================================================================
  // EVENT EMISSION
  // ===========================================================================

  /// Emits an event based on the provided item or context.
  /// This is called by mixins to emit type-safe events.
  @override
  void emitEvent(dynamic itemOrEvent) {
    if (itemOrEvent is InteractiveEvent<T>) {
      _eventController.add(itemOrEvent);
    }
  }

  /// Helper to emit typed events directly.
  void _emit(InteractiveEvent<T> event) {
    _eventController.add(event);
  }

  // Override interaction methods to emit proper events
  @override
  void select(T item) {
    super.select(item);
    _emit(ItemSelected(item));
  }

  @override
  void deselect([T? item]) {
    super.deselect(item);
    _emit(ItemDeselected(item));
  }

  @override
  void hover(T item) {
    super.hover(item);
    _emit(ItemHovered(item));
  }

  @override
  void clearHover([T? item]) {
    super.clearHover(item);
    _emit(HoverCleared(item));
  }

  @override
  void tap(T item) {
    super.tap(item);
    _emit(ItemTapped(item));
  }

  @override
  void longPress(T item) {
    super.longPress(item);
    _emit(ItemLongPressed(item));
  }

  // ===========================================================================
  // ENHANCED CRUD OPERATIONS
  // ===========================================================================

  @override
  void add(T item, {bool notify = true}) {
    // Incremental Update
    _itemCache[logic.getItemKey(item)!] = item;
    spatialIndex.add(logic.getItemKey(item)!, item, logic.getBounds(item));

    perform(logic.createAddOp(item), notify: notify);
    if (notify) _emit(ItemAdded(item));
    scheduleAutoSave();
  }

  @override
  void update(Key key, T newItem, {bool merge = false}) {
    final oldItem = findByKey(key);
    if (oldItem == null) return;

    final oldBounds = logic.getBounds(oldItem);
    final newBounds = logic.getBounds(newItem);

    // Incremental Update
    _itemCache[key] = newItem;
    spatialIndex.update(key, newItem, oldBounds, newBounds);

    perform(logic.createUpdateOp(oldItem, newItem), merge: merge, notify: true);
    _emit(ItemUpdated(oldItem, newItem));
    scheduleAutoSave();
  }

  @override
  void remove(Key key, {VoidCallback? onBeforeRemove}) {
    final removedItem = findByKey(key);
    if (removedItem == null) return;

    // Clean up interaction state before removal
    if (isActiveKey(key)) deselect();
    if (isHoveredKey(key)) clearHover();
    if (isLongPressedKey(key)) clearLongPress();

    // Incremental Update
    _itemCache.remove(key);
    spatialIndex.remove(key);

    onBeforeRemove?.call();
    perform(logic.createRemoveOp(key), notify: true);
    _emit(ItemRemoved(removedItem));
    scheduleAutoSave();
  }

  // ===========================================================================
  // ENHANCED SAVE WITH DELTA CALCULATION
  // ===========================================================================

  @override
  void save({bool erase = false}) {
    _cancelAutoSave();
    final oldState =
        List<T>.of(internalSaved.isNotEmpty ? internalSaved : internalInitial);

    super.save(erase: erase);

    final currentState = internalCurrent;
    final delta = calculateDelta(
      oldState: oldState,
      newState: currentState,
      keySelector: (item) => logic.getItemKey(item)!,
      hasSpatialChange: logic.hasSpatialChange,
    );

    _onSavedCallback?.call(delta);
  }

  @override
  void discard() {
    _cancelAutoSave();
    super.discard();
    _refreshReferences();
  }

  @override
  void abort() {
    _cancelAutoSave();
    super.abort();
    _refreshReferences();
  }

  // ===========================================================================
  // PROTECTED HELPERS
  // ===========================================================================

  @protected
  void perform(Op<T> op, {bool merge = false, bool notify = true}) {
    _transactions.commit(op, merge: merge, notify: notify);
    _refreshReferences();
  }

  @protected
  void scheduleAutoSave() {
    if (!_options.autoSave || !_editMode) return;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_options.autoSaveDelay, () {
      if (!_editMode || !_hasUnsavedChanges()) return;
      save();
    });
  }

  void _cancelAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  void _refreshReferences() {
    final currentList = _transactions.current;

    // Optim: Rebuild cache map for O(1) lookups
    _itemCache.clear();
    for (final item in currentList) {
      final key = logic.getItemKey(item);
      if (key != null) _itemCache[key] = item;
    }

    // Refresh dependencies using O(1) Lookups
    refreshInteractionReferences(_itemCache.keys.toSet());

    // Lazy Spatial Index Rebuild
    _indexDirty = true;
  }

  bool _hasUnsavedChanges() {
    final savedState =
        internalSaved.isNotEmpty ? internalSaved : internalInitial;
    return !listEquals(internalCurrent, savedState);
  }

  void _handleHistoryChanged() {
    _emit(HistoryChanged(
      current: List<T>.unmodifiable(_transactions.current),
      canUndo: canUndo,
      canRedo: canRedo,
      historyDepth: _transactions.history.length,
    ));
    notifyListeners();
  }
}
