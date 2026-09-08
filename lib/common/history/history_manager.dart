import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_interactive/common/history/history.dart';
import 'package:flutter_map_interactive/common/history/op.dart';

class MergeState<T> {
  MergeState(this.op, this.epochMs);
  final Op<T> op;
  final int epochMs;
}

/// Manages the transactional state of a list of entities [T].
///
/// Handles:
/// - Undo/Redo history
/// - Merging of continuous operations (e.g. drag)
/// - State storage (current, initial, saved)
class HistoryManager<T> extends ChangeNotifier {
  HistoryManager({this.maxHistoryDepth = 100});
  final History<Op<T>> _history = History<Op<T>>();
  final int maxHistoryDepth;

  Duration _mergeDelay = const Duration(milliseconds: 500);
  MergeState<T>? _lastMerge;

  int Function()? _nowMs;
  int _now() => _nowMs?.call() ?? DateTime.now().millisecondsSinceEpoch;

  @visibleForTesting
  set testNowMs(int Function() f) => _nowMs = f;

  // ===========================================================================
  // STATE
  // ===========================================================================

  List<T> _initial = [];
  List<T> _current = [];
  List<T> _saved = [];
  int _version = 0;

  List<T> get current =>
      _current; // Internal mutable access for convenience within package? Or Unmodifiable?
  // InteractiveController needs mutable access mostly? No, it usually just reads or calls ops.
  // Actually, ops apply to Mutable List.
  // Let's expose Unmodifiable for public, but we might need internal mutable access for ops.
  // Ops apply(List<T>)

  // Expose unmodifiable views for consumers
  List<T> get readOnlyCurrent => UnmodifiableListView(_current);
  List<T> get readOnlySaved => UnmodifiableListView(_saved);
  List<T> get readOnlyInitial => UnmodifiableListView(_initial);

  int get version => _version;

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  List<Op<T>> get history => _history.ops;

  void setMergeDelay(Duration delay) {
    _mergeDelay = delay;
  }

  // ===========================================================================
  // TRANSACTIONS
  // ===========================================================================

  void commit(Op<T> op, {bool merge = false, bool notify = true}) {
    // Apply logic on _current
    final effectiveOp = op.apply(_current);

    if (merge && _lastMerge != null) {
      final now = _now();
      final last = _lastMerge!;
      final within = (now - last.epochMs) <= _mergeDelay.inMilliseconds;

      if (within && last.op.canMerge(effectiveOp)) {
        effectiveOp.revert(_current);
        last.op.revert(_current);

        final fused = last.op.merge(effectiveOp);
        final fusedEffective = fused.apply(_current);

        _history.replaceLast(fusedEffective);
        _lastMerge = MergeState(fusedEffective, now);

        _version++;
        if (notify) notifyListeners();
        return;
      }
    }

    _history.push(effectiveOp);
    _lastMerge = merge ? MergeState(effectiveOp, _now()) : null;

    // Enforce max depth to prevent unbounded memory growth
    _history.trimToSize(maxHistoryDepth);

    _version++;

    if (notify) notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    final op = _history.popUndo();
    op.revert(_current);
    _lastMerge = null;
    _version++;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final op = _history.popRedo();
    op.apply(_current);
    _lastMerge = MergeState(op, _now());
    _version++;
    notifyListeners();
  }

  // ===========================================================================
  // DATA MANAGEMENT
  // ===========================================================================

  void save({bool erase = false}) {
    _saved = List<T>.of(_current);
    if (erase) {
      _initial = List<T>.of(_saved);
      _history.clear();
      _lastMerge = null;
    }
    notifyListeners();
  }

  void discard() {
    _current = List<T>.of(_saved);
    _history.clear();
    _lastMerge = null;
    _version++;
    notifyListeners();
  }

  void abort() {
    _current = List<T>.of(_initial);
    _history.clear();
    _lastMerge = null;
    _version++;
    notifyListeners();
  }

  void setItems(List<T> items, {required bool resetHistory}) {
    _current = List<T>.of(items);

    if (resetHistory) {
      _initial = List<T>.of(items);
      _saved = List<T>.of(items);
      _history.clear();
      _lastMerge = null;
    } else {
      if (_initial.isEmpty) {
        _initial = List<T>.of(items);
      }
      if (_saved.isEmpty) {
        _saved = List<T>.of(items);
      }
    }
    _version++;
    notifyListeners();
  }
}
