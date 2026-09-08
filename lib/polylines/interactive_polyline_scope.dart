import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/interactive_scope.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/scope_helpers.dart';
import 'package:flutter_map_interactive/polylines/controllers/polyline_controller.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';

class InteractivePolylineScope extends StatelessWidget {
  const InteractivePolylineScope({
    super.key,
    required this.controller,
    this.options = const InteractiveOptions(),
    required this.builder,
  });
  final PolylineController controller;
  final InteractiveOptions<InteractivePolyline> options;

  final Widget Function(
      BuildContext context, List<InteractivePolyline> polylines) builder;

  static PolylineController? maybeControllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        InheritedInteractiveScope<InteractivePolyline>>();
    return scope?.controller as PolylineController?;
  }

  static PolylineController controllerOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    if (controller == null) {
      throw FlutterError(
          '`PolylineController.of()` called without a `InteractivePolylineScope` ancestor.');
    }
    return controller;
  }

  static InteractiveOptions<InteractivePolyline>? maybeOptionsOf(
          BuildContext context) =>
      ScopeHelpers.maybeOptionsOf<InteractivePolyline>(context);

  static InteractiveOptions<InteractivePolyline> optionsOf(
          BuildContext context) =>
      ScopeHelpers.optionsOf<InteractivePolyline>(
          context, 'InteractivePolylineScope');

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
