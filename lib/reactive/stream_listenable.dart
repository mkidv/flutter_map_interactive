import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class StreamListenable<T> extends ChangeNotifier
    implements ValueListenable<T?> {
  StreamListenable(
    this._stream, {
    T? initialValue,
    this.mergeEvents = true,
    this.equals = _defaultEquals,
  }) : _value = initialValue {
    _sub = _stream.listen(_onData);
  }

  final Stream<T> _stream;
  final bool mergeEvents;
  final bool Function(T?, T?) equals;

  StreamSubscription<T>? _sub;
  T? _value;
  bool _scheduled = false;

  static bool _defaultEquals(dynamic a, dynamic b) => a == b;

  @override
  T? get value => _value;

  void _onData(T data) {
    if (equals(_value, data)) return;
    _value = data;

    if (!mergeEvents) {
      notifyListeners();
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

extension StreamToListenable<T> on Stream<T> {
  StreamListenable<T> asListenable({
    T? initialValue,
    bool mergeEvents = true,
    bool Function(T?, T?) equals = StreamListenable._defaultEquals,
  }) =>
      StreamListenable<T>(this,
          initialValue: initialValue, mergeEvents: mergeEvents, equals: equals);
}
