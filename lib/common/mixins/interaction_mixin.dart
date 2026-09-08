import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';

/// Mixin providing interaction state management (selection, hover, long-press).
mixin InteractionMixin<T> {
  /// Must be implemented to provide type-specific logic.
  EntityLogic<T> get logic;

  /// Must be implemented to notify listeners.
  void notifyListeners();

  /// Must be implemented to emit events.
  void emitEvent(dynamic event);

  /// Interaction state sets.
  final Set<Key> activeKeys = {};
  final Set<Key> hoveredKeys = {};
  final Set<Key> longPressedKeys = {};

  /// Callbacks for interactions (optional).
  ValueChanged<T>? get onTapCallback => null;
  ValueChanged<T>? get onActiveCallback => null;
  ValueChanged<T>? get onHoverCallback => null;
  ValueChanged<T>? get onLongPressCallback => null;

  // ===========================================================================
  // STATE QUERIES
  // ===========================================================================

  bool get hasActive => activeKeys.isNotEmpty;
  bool get hasHovered => hoveredKeys.isNotEmpty;

  Set<Key> get activeKeysView => UnmodifiableSetView(activeKeys);
  Set<Key> get hoveredKeysView => UnmodifiableSetView(hoveredKeys);
  Set<Key> get longPressedKeysView => UnmodifiableSetView(longPressedKeys);

  Key? get activeKey => activeKeys.isNotEmpty ? activeKeys.first : null;
  Key? get hoveredKey => hoveredKeys.isNotEmpty ? hoveredKeys.first : null;

  bool isActive(T item) => isActiveKey(logic.getItemKey(item));
  bool isActiveKey(Key? key) => key != null && activeKeys.contains(key);

  bool isHovered(T item) => isHoveredKey(logic.getItemKey(item));
  bool isHoveredKey(Key? key) => key != null && hoveredKeys.contains(key);

  bool isLongPressed(T item) => isLongPressedKey(logic.getItemKey(item));
  bool isLongPressedKey(Key? key) =>
      key != null && longPressedKeys.contains(key);

  // ===========================================================================
  // INTERACTION OPERATIONS
  // ===========================================================================

  void select(T item) {
    final key = logic.getItemKey(item);
    if (key == null) return;

    if (!isActiveKey(key)) {
      activeKeys.clear();
      activeKeys.add(key);
      longPressedKeys.clear();
      logic.onInteraction(item, InteractionType.active);
      onActiveCallback?.call(item);
      notifyListeners();
    }
  }

  void deselect([T? item]) {
    bool changed = false;

    if (item == null) {
      if (activeKeys.isNotEmpty) {
        activeKeys.clear();
        changed = true;
      }
      if (longPressedKeys.isNotEmpty) {
        longPressedKeys.clear();
        changed = true;
      }
    } else {
      final key = logic.getItemKey(item);
      if (key != null) {
        if (activeKeys.remove(key)) changed = true;
        if (longPressedKeys.remove(key)) changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void toggleSelect(T item) {
    final key = logic.getItemKey(item);
    if (key == null) return;

    if (isActiveKey(key)) {
      deselect(item);
    } else {
      select(item);
    }
  }

  void hover(T item) {
    final key = logic.getItemKey(item);
    if (key == null) return;

    hoveredKeys.clear();
    hoveredKeys.add(key);
    logic.onInteraction(item, InteractionType.hover);
    onHoverCallback?.call(item);
    notifyListeners();
  }

  void clearHover([T? item]) {
    if (item == null) {
      hoveredKeys.clear();
      notifyListeners();
    } else {
      final key = logic.getItemKey(item);
      if (key != null) hoveredKeys.remove(key);
      notifyListeners();
    }
  }

  void tap(T item) {
    logic.onInteraction(item, InteractionType.tap);
    onTapCallback?.call(item);
    toggleSelect(item);
  }

  void longPress(T item) {
    select(item);

    final key = logic.getItemKey(item);
    if (key != null) {
      longPressedKeys.clear();
      longPressedKeys.add(key);
      logic.onInteraction(item, InteractionType.longPress);
      onLongPressCallback?.call(item);
      notifyListeners();
    }
  }

  void clearLongPress([T? item]) {
    if (item == null) {
      longPressedKeys.clear();
    } else {
      final key = logic.getItemKey(item);
      if (key != null) longPressedKeys.remove(key);
    }
    notifyListeners();
  }

  void refreshInteractionReferences(Set<Key> currentKeys) {
    activeKeys.retainWhere(currentKeys.contains);
    hoveredKeys.retainWhere(currentKeys.contains);
    longPressedKeys.retainWhere(currentKeys.contains);
  }
}
