import 'package:flutter_map_interactive/common/entity_delta.dart';
import 'package:flutter_map_interactive/common/history/history_manager.dart';

/// Mixin providing transaction management capabilities (undo/redo/save).
///
/// Requires a [HistoryManager] to be available via the [history] getter.
mixin TransactionMixin<T> {
  /// Must be implemented by the using class to provide access to the history manager.
  HistoryManager<T> get history;

  /// Whether undo is available.
  bool get canUndo => history.canUndo;

  /// Whether redo is available.
  bool get canRedo => history.canRedo;

  /// Undo the last operation.
  void undo() => history.undo();

  /// Redo the previously undone operation.
  void redo() => history.redo();

  /// Saves the current state.
  ///
  /// If [erase] is true, clears the undo history.
  void save({bool erase = false}) => history.save(erase: erase);

  /// Discards all changes and reverts to the saved state.
  void discard() => history.discard();

  /// Abort all changes and reverts to the initial state.
  void abort() => history.abort();

  /// Gets the delta between old and new states.
  ///
  /// This is a utility method for calculating deltas, mainly used during save operations.
  EntityDelta<T> calculateDelta({
    required List<T> oldState,
    required List<T> newState,
    required Object Function(T) keySelector,
    required bool Function(T, T) hasSpatialChange,
  }) {
    return EntityDelta.diff(
      oldState,
      newState,
      keySelector: keySelector,
      hasSpatialChange: hasSpatialChange,
    );
  }
}
