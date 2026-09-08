import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/interactive_controller.dart';
import 'package:flutter_map_interactive/common/options.dart';

class InheritedInteractiveScope<T extends Object> extends InheritedWidget {
  const InheritedInteractiveScope({
    super.key,
    required this.controller,
    this.options = const InteractiveOptions(),
    required super.child,
  });
  final InteractiveController<T> controller;
  final InteractiveOptions<T> options;

  @override
  bool updateShouldNotify(InheritedInteractiveScope oldWidget) {
    return oldWidget.controller != controller || oldWidget.options != options;
  }
}
