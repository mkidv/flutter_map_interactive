import 'package:flutter_map_interactive/common/history/history_manager.dart';

/// A generic operation that can be applied to a list of items [T].
///
/// Used by [HistoryManager] to manage history, undo, redo, and merging.
abstract class Op<T> {
  /// Applies this operation to the [current] list.
  ///
  /// Modifies [current] in place and returns the *effective* operation
  /// (e.g. populated with captured state like removed index).
  Op<T> apply(List<T> current);

  /// Reverts this operation from the [current] list.
  ///
  /// Modifies [current] in place and returns the operation itself (or reversed op).
  Op<T> revert(List<T> current);

  /// Checks if this operation can be merged with [other].
  bool canMerge(Op<T> other);

  /// Merges this operation with [other], returning a new operation.
  Op<T> merge(Op<T> other);
}
