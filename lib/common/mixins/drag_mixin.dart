import 'package:flutter/foundation.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/events.dart';
import 'package:flutter_map_interactive/common/history/op.dart';
import 'package:flutter_map_interactive/common/transient_state.dart';
import 'package:latlong2/latlong.dart';

/// Mixin providing drag operation management.
mixin DragMixin<T> {
  /// Must be implemented to provide type-specific logic.
  EntityLogic<T> get logic;

  /// Must be implemented to notify listeners.
  void notifyListeners();

  /// Must be implemented to perform operations.
  void performOp(Op<T> op, {bool merge = false});

  /// Must be implemented to emit interaction events.
  void emitEvent(dynamic itemOrEvent);

  /// Transient state for drag operations.
  final ValueNotifier<TransientState<T>?> transientStateNotifier =
      ValueNotifier(null);
  final Set<Key> transientKeys = {};

  /// Exposes transient state as a listenable.
  ValueListenable<TransientState<T>?> get transientState =>
      transientStateNotifier;

  /// Checks if an item is in transient state.
  bool isTransient(T item) => isTransientKey(logic.getItemKey(item));

  /// Checks if a key is in transient state.
  bool isTransientKey(Key? key) => key != null && transientKeys.contains(key);

  // ===========================================================================
  // DRAG OPERATIONS
  // ===========================================================================

  /// Starts a drag operation.
  void startDrag(T item, LatLng origin) {
    if (transientStateNotifier.value != null) return;

    final key = logic.getItemKey(item);
    if (key != null) {
      transientKeys.add(key);
      transientStateNotifier.value =
          TransientState(item: item, current: origin, origin: origin);
      emitEvent(DragStarted(item, origin));
      notifyListeners();
    }
  }

  /// Updates the current drag position.
  void updateDrag(LatLng current) {
    final state = transientStateNotifier.value;
    if (state == null) return;

    final key = logic.getItemKey(state.item);
    if (key != null) {
      transientStateNotifier.value = state.copyWith(current: current);
      logic.onDragUpdate(state.item, state.origin, current);
      emitEvent(DragUpdated(state.item, state.origin, current));
    }
  }

  /// Ends the drag operation and commits the change.
  void endDrag() {
    final state = transientStateNotifier.value;
    if (state == null) return;

    final op = logic.createDragEndOp(state.item, state.origin, state.current);
    if (op != null) {
      performOp(op, merge: true);
    }
    emitEvent(DragEnded(state.item, state.origin, state.current));

    final key = logic.getItemKey(state.item);
    if (key != null) transientKeys.remove(key);
    transientStateNotifier.value = null;
    notifyListeners();
  }

  void disposeDrag() {
    transientStateNotifier.dispose();
  }
}
