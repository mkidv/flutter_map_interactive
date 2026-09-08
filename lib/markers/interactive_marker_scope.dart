import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:flutter_map_interactive/common/interactive_scope.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/scope_helpers.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';

import 'package:flutter_map_interactive/reactive/selector.dart';

class InteractiveMarkerScope extends StatelessWidget {
  const InteractiveMarkerScope({
    super.key,
    required this.controller,
    this.options = const InteractiveOptions(),
    required this.builder,
  });
  final MarkerController controller;
  final InteractiveOptions<Marker> options;

  final Widget Function(BuildContext context, List<Marker> markers) builder;

  static MarkerController? maybeControllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        InheritedInteractiveScope<Marker>>();
    return scope?.controller as MarkerController;
  }

  static MarkerController controllerOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    if (controller == null) {
      throw FlutterError(
          'MarkerController.of() called without an `InteractiveMarkerScope` ancestor.');
    }
    return controller;
  }

  static InteractiveOptions<Marker>? maybeOptionsOf(BuildContext context) =>
      ScopeHelpers.maybeOptionsOf<Marker>(context);

  static InteractiveOptions<Marker> optionsOf(BuildContext context) =>
      ScopeHelpers.optionsOf<Marker>(context, 'InteractiveMarkerScope');

  @override
  Widget build(BuildContext context) {
    return InheritedInteractiveScope(
      controller: controller,
      options: options,
      child: ListenableSelector(
        listenable: controller,
        select: (c) => (c.version, current: c.current, editing: c.isEditing),
        builder: (context, state) => builder(context, state.current),
      ),
    );
  }
}
