/// Represents a set of changes (added, removed, moved, updated) between two lists of entities.
class EntityDelta<T> {
  const EntityDelta({
    this.added = const [],
    this.removed = const [],
    this.moved = const [],
    this.updated = const [],
  });

  /// Computes the difference between two lists.
  factory EntityDelta.diff(
    List<T> oldL,
    List<T> newL, {
    required Object Function(T) keySelector,
    required bool Function(T oldItem, T newItem) hasSpatialChange,
  }) {
    final oldByKey = {for (final item in oldL) keySelector(item): item};
    final newByKey = {for (final item in newL) keySelector(item): item};

    final added = <T>[];
    final removed = <T>[];
    final moved = <(T, T)>[];
    final updated = <(T, T)>[];

    // Find removed
    for (final key in oldByKey.keys) {
      if (!newByKey.containsKey(key)) {
        removed.add(oldByKey[key] as T);
      }
    }

    // Find added, moved, updated
    for (final key in newByKey.keys) {
      final newItem = newByKey[key] as T;
      final oldItem = oldByKey[key];

      if (oldItem == null) {
        added.add(newItem);
        continue;
      }

      if (hasSpatialChange(oldItem, newItem)) {
        moved.add((oldItem, newItem));
        continue;
      }

      if (newItem != oldItem) {
        updated.add((oldItem, newItem));
      }
    }

    return EntityDelta(
      added: added,
      removed: removed,
      moved: moved,
      updated: updated,
    );
  }

  /// Items that were added.
  final List<T> added;

  /// Items that were removed.
  final List<T> removed;

  /// Items that moved spatially (old, new).
  final List<(T, T)> moved;

  /// Items that were updated (non-spatial change) (old, new).
  final List<(T, T)> updated;

  /// Returns true if any changes occurred.
  bool get hasChanged =>
      added.isNotEmpty ||
      removed.isNotEmpty ||
      moved.isNotEmpty ||
      updated.isNotEmpty;

  /// All old items affected by changes.
  List<T> get olds => [
        ...removed,
        ...moved.map((e) => e.$1),
        ...updated.map((e) => e.$1),
      ];

  /// All new items after changes.
  List<T> get news => [
        ...added,
        ...moved.map((e) => e.$2),
        ...updated.map((e) => e.$2),
      ];

  EntityDelta<T> copyWith({
    List<T>? added,
    List<T>? removed,
    List<(T, T)>? moved,
    List<(T, T)>? updated,
  }) {
    return EntityDelta<T>(
      added: added ?? this.added,
      removed: removed ?? this.removed,
      moved: moved ?? this.moved,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityDelta<T> &&
          runtimeType == other.runtimeType &&
          _listEquals(added, other.added) &&
          _listEquals(removed, other.removed) &&
          _tupleListEquals(moved, other.moved) &&
          _tupleListEquals(updated, other.updated);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(added),
        Object.hashAll(removed),
        Object.hashAll(moved),
        Object.hashAll(updated),
      );

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _tupleListEquals<E>(List<(E, E)> a, List<(E, E)> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].$1 != b[i].$1 || a[i].$2 != b[i].$2) return false;
    }
    return true;
  }
}
