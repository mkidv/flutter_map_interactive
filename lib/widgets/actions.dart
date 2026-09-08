import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;

import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';

typedef MarkerActionCallback = void Function(
  Marker marker, {
  MarkerController? controller,
});

typedef MarkerActionBuilder = Widget Function(
  BuildContext context,
  Marker marker, {
  MarkerController? controller,
});

class MarkerActionMenu extends StatelessWidget {
  const MarkerActionMenu({
    super.key,
    required this.actions,
    this.spacing = 8.0,
    this.direction = Axis.horizontal,
    this.padding,
    this.decoration,
  });
  final List<Widget> actions;
  final double spacing;
  final Axis direction;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: decoration ??
          BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withAlpha(120),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
      child: Flex(
        direction: direction,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: actions,
      ),
    );
  }
}

class MarkerAction extends StatelessWidget {
  const MarkerAction({
    super.key,
    required this.builder,
  });
  final MarkerActionBuilder builder;

  @override
  Widget build(BuildContext context) {
    final controller = MarkerController.of(context);
    final marker = controller.longPressedItem;
    if (marker == null) {
      return const SizedBox.shrink();
    }
    return builder(
      context,
      marker,
      controller: controller,
    );
  }
}

class SimpleMarkerAction extends StatelessWidget {
  const SimpleMarkerAction({
    super.key,
    required this.onPressed,
    required this.icon,
    this.decoration,
    this.width = 40,
    this.height = 40,
  });
  final MarkerActionCallback onPressed;
  final Icon icon;
  final BoxDecoration? decoration;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final controller = MarkerController.of(context);
    final marker = controller.longPressedItem;
    if (marker == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPressed(
            marker,
            controller: controller,
          ),
          child: DecoratedBox(
            decoration: decoration ?? const BoxDecoration(),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class ExpandableMarkerAction extends StatefulWidget {
  const ExpandableMarkerAction({
    super.key,
    required this.icon,
    required this.expandedActions,
    this.collapsedWidth = 50,
    this.collapsedHeight = 50,
    this.spacing = 8,
    this.direction = Axis.horizontal,
    this.duration = const Duration(milliseconds: 120),
    this.decoration,
  });
  final Icon icon;
  final List<Widget> expandedActions;
  final double collapsedWidth;
  final double collapsedHeight;
  final double spacing;
  final Axis direction;
  final Duration duration;
  final BoxDecoration? decoration;

  @override
  State<ExpandableMarkerAction> createState() => _ExpandableMarkerActionState();
}

class _ExpandableMarkerActionState extends State<ExpandableMarkerAction> {
  bool _expanded = false;

  void expand(Marker marker, {MarkerController? controller}) {
    setState(() => _expanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = SimpleMarkerAction(
      onPressed: expand,
      icon: widget.icon,
      width: widget.collapsedWidth,
      height: widget.collapsedHeight,
      decoration: widget.decoration,
    );

    final expanded = Container(
      decoration: widget.decoration,
      child: Wrap(
        direction: widget.direction,
        spacing: widget.spacing,
        runSpacing: widget.spacing,
        alignment: WrapAlignment.center,
        children: widget.expandedActions,
      ),
    );

    return AnimatedSize(
      duration: widget.duration,
      curve: Curves.easeInOut,
      child: _expanded ? expanded : collapsed,
    );
  }
}

class TrashMarkerAction extends StatelessWidget {
  const TrashMarkerAction({
    super.key,
    this.onConfirm = defaultOnConfirm,
    this.onCancel = defaultOnCancel,
  });

  const TrashMarkerAction.custom({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });
  final MarkerActionCallback onConfirm;
  final MarkerActionCallback onCancel;

  static void defaultOnConfirm(
    Marker marker, {
    MarkerController? controller,
  }) {
    marker.ensureHasKey();
    controller?.remove(marker.key!);
    controller?.deselect();
  }

  static void defaultOnCancel(
    Marker marker, {
    MarkerController? controller,
  }) {
    controller?.deselect();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableMarkerAction(
      icon: const Icon(Icons.delete),
      expandedActions: [
        SimpleMarkerAction(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: onConfirm,
        ),
        SimpleMarkerAction(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: onCancel,
        ),
      ],
    );
  }
}
