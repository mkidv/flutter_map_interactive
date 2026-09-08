import 'package:latlong2/latlong.dart';

/// Base sealed class for all interactive events.
///
/// Events are emitted by [InteractiveController] and can be consumed via the [events] stream.
/// This allows for reactive programming patterns and better composability.
sealed class InteractiveEvent<T> {
  InteractiveEvent() : timestamp = DateTime.now();

  /// Timestamp when the event was created.
  final DateTime timestamp;
}

// ===========================================================================
// INTERACTION EVENTS
// ===========================================================================

/// Emitted when an item is tapped.
final class ItemTapped<T> extends InteractiveEvent<T> {
  ItemTapped(this.item);
  final T item;

  @override
  String toString() => 'ItemTapped($item)';
}

/// Emitted when an item becomes selected/active.
final class ItemSelected<T> extends InteractiveEvent<T> {
  ItemSelected(this.item);
  final T item;

  @override
  String toString() => 'ItemSelected($item)';
}

/// Emitted when an item is deselected.
/// If [item] is null, all items were deselected.
final class ItemDeselected<T> extends InteractiveEvent<T> {
  ItemDeselected(this.item);
  final T? item;

  @override
  String toString() => 'ItemDeselected(${item ?? 'all'})';
}

/// Emitted when an item is hovered.
final class ItemHovered<T> extends InteractiveEvent<T> {
  ItemHovered(this.item);
  final T item;

  @override
  String toString() => 'ItemHovered($item)';
}

/// Emitted when hover is cleared from an item.
final class HoverCleared<T> extends InteractiveEvent<T> {
  HoverCleared(this.item);
  final T? item;

  @override
  String toString() => 'HoverCleared(${item ?? 'all'})';
}

/// Emitted when an item is long-pressed.
final class ItemLongPressed<T> extends InteractiveEvent<T> {
  ItemLongPressed(this.item);
  final T item;

  @override
  String toString() => 'ItemLongPressed($item)';
}

// ===========================================================================
// HISTORY EVENTS
// ===========================================================================

/// Emitted when the history state changes (after add/remove/update/undo/redo).
final class HistoryChanged<T> extends InteractiveEvent<T> {
  HistoryChanged({
    required this.current,
    required this.canUndo,
    required this.canRedo,
    required this.historyDepth,
  });
  final List<T> current;
  final bool canUndo;
  final bool canRedo;
  final int historyDepth;

  @override
  String toString() =>
      'HistoryChanged(items: ${current.length}, undo: $canUndo, redo: $canRedo)';
}

// ===========================================================================
// DRAG EVENTS
// ===========================================================================

/// Emitted when a drag operation starts.
final class DragStarted<T> extends InteractiveEvent<T> {
  DragStarted(this.item, this.origin);
  final T item;
  final LatLng origin;

  @override
  String toString() => 'DragStarted($item at $origin)';
}

/// Emitted during drag updates (position changes).
final class DragUpdated<T> extends InteractiveEvent<T> {
  DragUpdated(this.item, this.origin, this.current);
  final T item;
  final LatLng origin;
  final LatLng current;

  @override
  String toString() => 'DragUpdated($item to $current)';
}

/// Emitted when a drag operation ends.
final class DragEnded<T> extends InteractiveEvent<T> {
  DragEnded(this.item, this.origin, this.finalPosition);
  final T item;
  final LatLng origin;
  final LatLng finalPosition;

  @override
  String toString() => 'DragEnded($item at $finalPosition)';
}

// ===========================================================================
// EDIT MODE EVENTS
// ===========================================================================

/// Emitted when edit mode is toggled.
final class EditModeChanged<T> extends InteractiveEvent<T> {
  EditModeChanged(this.isEditing);
  final bool isEditing;

  @override
  String toString() => 'EditModeChanged(isEditing: $isEditing)';
}

// ===========================================================================
// CRUD EVENTS
// ===========================================================================

/// Emitted when an item is added.
final class ItemAdded<T> extends InteractiveEvent<T> {
  ItemAdded(this.item);
  final T item;

  @override
  String toString() => 'ItemAdded($item)';
}

/// Emitted when an item is removed.
final class ItemRemoved<T> extends InteractiveEvent<T> {
  ItemRemoved(this.item);
  final T item;

  @override
  String toString() => 'ItemRemoved($item)';
}

/// Emitted when an item is updated.
final class ItemUpdated<T> extends InteractiveEvent<T> {
  ItemUpdated(this.oldItem, this.newItem);
  final T oldItem;
  final T newItem;

  @override
  String toString() => 'ItemUpdated($oldItem -> $newItem)';
}
