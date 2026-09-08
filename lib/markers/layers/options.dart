import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_map_interactive/markers/controllers/marker_controller.dart';

typedef MarkerWidgetBuilder = Widget Function(
  BuildContext context,
  MarkerController controller,
  Marker marker,
);

/// Base options for marker layers.
class MarkerLayerOptions {
  const MarkerLayerOptions({
    this.builder,
    this.alignment = Alignment.center,
    this.rotate = false,
  });

  /// Custom builder for marker widgets.
  final MarkerWidgetBuilder? builder;

  /// Alignment of markers relative to their position.
  final Alignment alignment;

  /// Whether markers should rotate with the map.
  final bool rotate;

  MarkerLayerOptions copyWith({
    MarkerWidgetBuilder? builder,
    Alignment? alignment,
    bool? rotate,
  }) {
    return MarkerLayerOptions(
      builder: builder ?? this.builder,
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerLayerOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate;

  @override
  int get hashCode => Object.hash(alignment, rotate);
}

/// Options for interactive marker layer with active state support.
class InteractiveLayerOptions extends MarkerLayerOptions {
  const InteractiveLayerOptions({
    super.builder,
    super.alignment = Alignment.center,
    super.rotate = true,
    this.activeBuilder,
    this.activeSizeFactor = 1.0,
    this.touchSizeFactor = 1.15,
  });

  /// Builder for the active state of a marker.
  final MarkerWidgetBuilder? activeBuilder;

  /// Size factor when marker is active.
  final double activeSizeFactor;

  /// Size factor for touch targets.
  final double touchSizeFactor;

  @override
  InteractiveLayerOptions copyWith({
    MarkerWidgetBuilder? builder,
    Alignment? alignment,
    bool? rotate,
    MarkerWidgetBuilder? activeBuilder,
    double? activeSizeFactor,
    double? touchSizeFactor,
  }) {
    return InteractiveLayerOptions(
      builder: builder ?? this.builder,
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      activeBuilder: activeBuilder ?? this.activeBuilder,
      activeSizeFactor: activeSizeFactor ?? this.activeSizeFactor,
      touchSizeFactor: touchSizeFactor ?? this.touchSizeFactor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveLayerOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          activeSizeFactor == other.activeSizeFactor &&
          touchSizeFactor == other.touchSizeFactor;

  @override
  int get hashCode => Object.hash(
        alignment,
        rotate,
        activeSizeFactor,
        touchSizeFactor,
      );
}

/// Options for popup layer.
class PopupLayerOptions extends MarkerLayerOptions {
  const PopupLayerOptions({
    super.builder,
    super.alignment = Alignment.topCenter,
    super.rotate = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
    this.margin,
  });

  /// Duration of popup animation.
  final Duration animationDuration;

  /// Curve for popup animation.
  final Curve animationCurve;

  /// Margin around popup.
  final EdgeInsets? margin;

  @override
  PopupLayerOptions copyWith({
    MarkerWidgetBuilder? builder,
    Alignment? alignment,
    bool? rotate,
    Duration? animationDuration,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return PopupLayerOptions(
      builder: builder ?? this.builder,
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PopupLayerOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          animationDuration == other.animationDuration &&
          animationCurve == other.animationCurve &&
          margin == other.margin;

  @override
  int get hashCode => Object.hash(
        alignment,
        rotate,
        animationDuration,
        animationCurve,
        margin,
      );
}

/// Options for label layer.
class LabelLayerOptions extends MarkerLayerOptions {
  const LabelLayerOptions({
    super.builder,
    super.alignment = Alignment.bottomRight,
    super.rotate = true,
    this.hideOnEdit = false,
    this.margin,
    this.strategy = const StickyGoldenFanStrategy(hysteresisPx: 3.0),
    this.collision = const CollisionOptions(),
  });

  /// Whether to hide labels when in edit mode.
  final bool hideOnEdit;

  /// Margin around label.
  final EdgeInsets? margin;

  final CollisionStrategy strategy;

  /// Collision detection options.
  final CollisionOptions collision;

  @override
  LabelLayerOptions copyWith({
    MarkerWidgetBuilder? builder,
    Alignment? alignment,
    bool? rotate,
    bool? hideOnEdit,
    EdgeInsets? margin,
    CollisionStrategy? strategy,
    CollisionOptions? collision,
  }) {
    return LabelLayerOptions(
      builder: builder ?? this.builder,
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      hideOnEdit: hideOnEdit ?? this.hideOnEdit,
      margin: margin ?? this.margin,
      strategy: strategy ?? this.strategy,
      collision: collision ?? this.collision,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelLayerOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          hideOnEdit == other.hideOnEdit &&
          margin == other.margin &&
          strategy == other.strategy &&
          collision == other.collision;

  @override
  int get hashCode => Object.hash(
        alignment,
        rotate,
        hideOnEdit,
        margin,
        strategy,
        collision,
      );
}

/// Options for action layer (edit mode actions).
class ActionLayerOptions extends MarkerLayerOptions {
  const ActionLayerOptions({
    super.builder,
    super.alignment = Alignment.topRight,
    super.rotate = true,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
    this.margin,
  });

  /// Duration of action animation.
  final Duration animationDuration;

  /// Curve for action animation.
  final Curve animationCurve;

  /// Margin around action widget.
  final EdgeInsets? margin;

  @override
  ActionLayerOptions copyWith({
    MarkerWidgetBuilder? builder,
    Alignment? alignment,
    bool? rotate,
    Duration? animationDuration,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return ActionLayerOptions(
      builder: builder ?? this.builder,
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionLayerOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          animationDuration == other.animationDuration &&
          animationCurve == other.animationCurve &&
          margin == other.margin;

  @override
  int get hashCode => Object.hash(
        alignment,
        rotate,
        animationDuration,
        animationCurve,
        margin,
      );
}
