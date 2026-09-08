import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/interactive_scope.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/common/scope_helpers.dart';
import 'package:flutter_map_interactive/overlays/controllers/overlay_controller.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';

import 'package:flutter_map_interactive/reactive/selector.dart';

class InteractiveOverlayScope extends StatelessWidget {
  const InteractiveOverlayScope({
    super.key,
    required this.controller,
    this.options = const InteractiveOptions(),
    required this.builder,
  });
  final OverlayController controller;
  final InteractiveOptions<InteractiveOverlayImage> options;

  final Widget Function(
      BuildContext context, List<InteractiveOverlayImage> overlays) builder;

  static OverlayController? maybeControllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        InheritedInteractiveScope<InteractiveOverlayImage>>();
    return scope?.controller as OverlayController?;
  }

  static OverlayController of(BuildContext context) {
    final controller = maybeControllerOf(context);
    if (controller == null) {
      throw FlutterError(
          'OverlayController.of() called without an `InteractiveOverlayScope` ancestor.');
    }
    return controller;
  }

  static InteractiveOptions<InteractiveOverlayImage>? maybeOptionsOf(
          BuildContext context) =>
      ScopeHelpers.maybeOptionsOf<InteractiveOverlayImage>(context);

  static InteractiveOptions<InteractiveOverlayImage> optionsOf(
          BuildContext context) =>
      ScopeHelpers.optionsOf<InteractiveOverlayImage>(
          context, 'InteractiveOverlayScope');

  @override
  Widget build(BuildContext context) {
    return InheritedInteractiveScope(
      controller: controller,
      options: options,
      child: ListenableSelector(
        listenable: controller,
        select: (c) => (c.version, current: c.current, isEditing: c.isEditing),
        builder: (context, state) => builder(context, state.current),
      ),
    );
  }
}
