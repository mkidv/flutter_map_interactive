import 'dart:collection';

import 'package:flutter_map_interactive/common/history/op.dart';

class History<T extends Op<Object?>> {
  final List<T> _ops = <T>[];
  int _cursor = -1;

  void clear() {
    _ops.clear();
    _cursor = -1;
  }

  bool get isEmpty => _ops.isEmpty;
  T? get last => _cursor >= 0 ? _ops[_cursor] : null;

  List<T> get ops => UnmodifiableListView(_ops);

  bool get canUndo => _cursor >= 0;
  bool get canRedo => _cursor < _ops.length - 1;

  void push(T op) {
    if (_cursor < _ops.length - 1) {
      _ops.removeRange(_cursor + 1, _ops.length);
    }
    _ops.add(op);
    _cursor = _ops.length - 1;
  }

  void replaceLast(T op) {
    assert(_cursor >= 0);
    _ops[_cursor] = op;
    if (_cursor < _ops.length - 1) {
      _ops.removeRange(_cursor + 1, _ops.length);
    }
  }

  T popUndo() => _ops[_cursor--];

  T popRedo() => _ops[++_cursor];

  /// Trims the history to the specified maximum size.
  /// Removes oldest operations (FIFO) while maintaining cursor validity.
  void trimToSize(int maxSize) {
    if (_ops.length <= maxSize) return;

    final excess = _ops.length - maxSize;
    _ops.removeRange(0, excess);
    _cursor = (_cursor - excess).clamp(-1, _ops.length - 1);
  }
}
