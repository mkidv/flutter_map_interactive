import 'package:flutter/foundation.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/history/history_manager.dart';
import 'package:flutter_map_interactive/common/history/op.dart';

/// Mixin providing CRUD (Create, Read, Update, Delete) operations.
///
/// Requires:
/// - [logic] to provide type-specific operations
/// - [history] to provide transaction management
mixin CRUDMixin<T> {
  /// Must be implemented to provide type-specific logic.
  EntityLogic<T> get logic;

  /// Must be implemented to provide transaction management.
  HistoryManager<T> get history;

  /// Must be implemented to notify listeners.
  void notifyListeners();

  /// Callbacks for CRUD operations (optional).
  ValueChanged<T>? get onAddedCallback => null;
  ValueChanged<T>? get onRemovedCallback => null;
  ValueChanged<T>? get onUpdatedCallback => null;

  /// Adds an item to the collection.
  void add(T item, {bool notify = true}) {
    logic.ensureHasKey(item);
    _perform(logic.createAddOp(item), notify: notify);
    onAddedCallback?.call(item);
  }

  /// Removes an item by key.
  void remove(Key key, {VoidCallback? onBeforeRemove}) {
    final removedItem = findByKey(key);
    if (removedItem == null) return;

    onBeforeRemove?.call();
    _perform(logic.createRemoveOp(key));
    onRemovedCallback?.call(removedItem);
  }

  /// Updates an item.
  void update(Key key, T newItem, {bool merge = false}) {
    logic.ensureHasKey(newItem);
    final oldItem = findByKey(key);
    if (oldItem == null) return;

    _perform(logic.createUpdateOp(oldItem, newItem), merge: merge);
    onUpdatedCallback?.call(newItem);
  }

  /// Sets the entire collection.
  void setItems(List<T> items, {required bool resetHistory}) {
    history.setItems(items, resetHistory: resetHistory);
  }

  /// Performs an operation on the history.
  void _perform(Op<T> op, {bool merge = false, bool notify = true}) {
    history.commit(op, merge: merge, notify: notify);
  }

  /// Finds an item by key.
  T? findByKey(Key key);
}
