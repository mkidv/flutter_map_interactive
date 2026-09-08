import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer(this.duration);
  final Duration duration;
  Timer? _t;

  void run(VoidCallback action) {
    _t?.cancel();
    _t = Timer(duration, () {
      _t = null;
      action();
    });
  }

  void cancel() {
    _t?.cancel();
    _t = null;
  }
}
