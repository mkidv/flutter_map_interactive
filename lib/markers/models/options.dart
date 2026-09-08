import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Base sealed class for all marker options.
sealed class MarkerOptions {
  const MarkerOptions();
}

/// Options for the active state of a marker.
class ActiveMarkerOptions extends MarkerOptions {
  const ActiveMarkerOptions({
    required this.active,
    this.activeSizeFactor = 1.0,
    this.touchSizeFactor = 1.2,
  });

  /// Widget to display when marker is active.
  final Widget? active;

  /// Size factor when marker is active.
  final double activeSizeFactor;

  /// Size factor for touch targets.
  final double touchSizeFactor;

  ActiveMarkerOptions copyWith({
    Widget? active,
    double? activeSizeFactor,
    double? touchSizeFactor,
  }) {
    return ActiveMarkerOptions(
      active: active ?? this.active,
      activeSizeFactor: activeSizeFactor ?? this.activeSizeFactor,
      touchSizeFactor: touchSizeFactor ?? this.touchSizeFactor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveMarkerOptions &&
          runtimeType == other.runtimeType &&
          activeSizeFactor == other.activeSizeFactor &&
          touchSizeFactor == other.touchSizeFactor;

  @override
  int get hashCode => Object.hash(activeSizeFactor, touchSizeFactor);
}

/// Options for popup attached to a marker.
class PopupMarkerOptions extends MarkerOptions {
  const PopupMarkerOptions({
    this.alignment = Alignment.topCenter,
    this.rotate = true,
    required this.popup,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
    this.margin,
  });

  /// Alignment of popup relative to marker.
  final Alignment alignment;

  /// Whether popup should rotate with map.
  final bool rotate;

  /// The popup widget.
  final Widget popup;

  /// Duration of popup animation.
  final Duration animationDuration;

  /// Curve for popup animation.
  final Curve animationCurve;

  /// Margin around popup.
  final EdgeInsets? margin;

  PopupMarkerOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Widget? popup,
    Duration? animationDuration,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return PopupMarkerOptions(
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      popup: popup ?? this.popup,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PopupMarkerOptions &&
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

/// Options for label attached to a marker.
class LabelMarkerOptions extends MarkerOptions {
  const LabelMarkerOptions({
    this.alignment = Alignment.bottomRight,
    this.rotate = true,
    required this.label,
    this.hideOnEdit = false,
    this.margin,
  });

  /// Alignment of label relative to marker.
  final Alignment alignment;

  /// Whether label should rotate with map.
  final bool rotate;

  /// The label widget.
  final Widget label;

  /// Whether to hide label in edit mode.
  final bool hideOnEdit;

  /// Margin around label.
  final EdgeInsets? margin;

  LabelMarkerOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Widget? label,
    bool? hideOnEdit,
    EdgeInsets? margin,
  }) {
    return LabelMarkerOptions(
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      label: label ?? this.label,
      hideOnEdit: hideOnEdit ?? this.hideOnEdit,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelMarkerOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          hideOnEdit == other.hideOnEdit &&
          margin == other.margin;

  @override
  int get hashCode => Object.hash(alignment, rotate, hideOnEdit, margin);
}

/// Options for action widget attached to a marker.
class ActionMarkerOptions extends MarkerOptions {
  const ActionMarkerOptions({
    this.alignment = Alignment.topRight,
    this.rotate = true,
    required this.action,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
    this.margin,
  });

  /// Alignment of action relative to marker.
  final Alignment alignment;

  /// Whether action should rotate with map.
  final bool rotate;

  /// The action widget.
  final Widget action;

  /// Duration of action animation.
  final Duration animationDuration;

  /// Curve for action animation.
  final Curve animationCurve;

  /// Margin around action widget.
  final EdgeInsets? margin;

  ActionMarkerOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Widget? action,
    Duration? animationDuration,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return ActionMarkerOptions(
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      action: action ?? this.action,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionMarkerOptions &&
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

/// Options for gesture callbacks on a marker.
class GestureMarkerOptions extends MarkerOptions {
  const GestureMarkerOptions({
    this.onTap,
    this.onLongPress,
    this.onHover,
    this.onActive,
    this.onPositionChanged,
  });

  /// Callback when marker is tapped.
  final VoidCallback? onTap;

  /// Callback when marker is long-pressed.
  final VoidCallback? onLongPress;

  /// Callback when marker is hovered.
  final VoidCallback? onHover;

  /// Callback when marker becomes active.
  final VoidCallback? onActive;

  /// Callback when marker position changes.
  final void Function(LatLng oldPos, LatLng newPos)? onPositionChanged;

  GestureMarkerOptions copyWith({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onHover,
    VoidCallback? onActive,
    void Function(LatLng oldPos, LatLng newPos)? onPositionChanged,
  }) {
    return GestureMarkerOptions(
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onHover: onHover ?? this.onHover,
      onActive: onActive ?? this.onActive,
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
    );
  }

  // Callbacks are not compared for equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GestureMarkerOptions && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
