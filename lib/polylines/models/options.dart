import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Base sealed class for all polyline options.
sealed class PolylineOptions {
  const PolylineOptions();
}

/// Options for the active state of a polyline.
class ActivePolylineOptions extends PolylineOptions {
  const ActivePolylineOptions({
    this.color,
    this.strokeWidth,
    this.borderStrokeWidth,
    this.borderColor,
    this.gradientColors,
    this.pattern,
  });

  /// Override color when active.
  final Color? color;

  /// Override stroke width when active.
  final double? strokeWidth;

  /// Override border stroke width when active.
  final double? borderStrokeWidth;

  /// Override border color when active.
  final Color? borderColor;

  /// Override gradient colors when active.
  final List<Color>? gradientColors;

  /// Override stroke pattern when active.
  final StrokePattern? pattern;

  ActivePolylineOptions copyWith({
    Color? color,
    double? strokeWidth,
    double? borderStrokeWidth,
    Color? borderColor,
    List<Color>? gradientColors,
    StrokePattern? pattern,
  }) {
    return ActivePolylineOptions(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      borderStrokeWidth: borderStrokeWidth ?? this.borderStrokeWidth,
      borderColor: borderColor ?? this.borderColor,
      gradientColors: gradientColors ?? this.gradientColors,
      pattern: pattern ?? this.pattern,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivePolylineOptions &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          borderStrokeWidth == other.borderStrokeWidth &&
          borderColor == other.borderColor &&
          pattern == other.pattern;

  @override
  int get hashCode => Object.hash(
        color,
        strokeWidth,
        borderStrokeWidth,
        borderColor,
        pattern,
      );
}

/// Options for popup attached to a polyline.
class PopupPolylineOptions extends PolylineOptions {
  const PopupPolylineOptions({
    this.alignment = Alignment.topCenter,
    this.rotate = true,
    this.animationCurve = Curves.easeOut,
    this.margin,
  });

  /// Alignment of popup relative to polyline center.
  final Alignment alignment;

  /// Whether popup should rotate with map.
  final bool rotate;

  /// Curve for popup animation.
  final Curve animationCurve;

  /// Margin around popup.
  final EdgeInsets? margin;

  PopupPolylineOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return PopupPolylineOptions(
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      animationCurve: animationCurve ?? this.animationCurve,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PopupPolylineOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          animationCurve == other.animationCurve &&
          margin == other.margin;

  @override
  int get hashCode => Object.hash(alignment, rotate, animationCurve, margin);
}

/// Options for label attached to a polyline.
class LabelPolylineOptions extends PolylineOptions {
  const LabelPolylineOptions({
    this.alignment = Alignment.bottomRight,
    this.rotate = true,
    this.hideOnEdit = false,
    this.margin,
  });

  /// Alignment of label relative to polyline.
  final Alignment alignment;

  /// Whether label should rotate with map.
  final bool rotate;

  /// Whether to hide label in edit mode.
  final bool hideOnEdit;

  /// Margin around label.
  final EdgeInsets? margin;

  LabelPolylineOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    bool? hideOnEdit,
    EdgeInsets? margin,
  }) {
    return LabelPolylineOptions(
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      hideOnEdit: hideOnEdit ?? this.hideOnEdit,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelPolylineOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          hideOnEdit == other.hideOnEdit &&
          margin == other.margin;

  @override
  int get hashCode => Object.hash(alignment, rotate, hideOnEdit, margin);
}

/// Options for action widget attached to a polyline.
class ActionPolylineOptions extends PolylineOptions {
  const ActionPolylineOptions({
    this.alignment = Alignment.topRight,
    this.rotate = true,
    this.animationCurve = Curves.easeInOut,
    this.margin,
  });

  /// Alignment of action relative to polyline.
  final Alignment alignment;

  /// Whether action should rotate with map.
  final bool rotate;

  /// Curve for action animation.
  final Curve animationCurve;

  /// Margin around action widget.
  final EdgeInsets? margin;

  ActionPolylineOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return ActionPolylineOptions(
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      animationCurve: animationCurve ?? this.animationCurve,
      margin: margin ?? this.margin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionPolylineOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          animationCurve == other.animationCurve &&
          margin == other.margin;

  @override
  int get hashCode => Object.hash(alignment, rotate, animationCurve, margin);
}

/// Options for gesture callbacks on a polyline.
class GesturePolylineOptions extends PolylineOptions {
  const GesturePolylineOptions({
    this.onTap,
    this.onLongPress,
    this.onHover,
    this.onPositionChanged,
  });

  /// Callback when polyline is tapped.
  final VoidCallback? onTap;

  /// Callback when polyline is long-pressed.
  final VoidCallback? onLongPress;

  /// Callback when polyline is hovered.
  final VoidCallback? onHover;

  /// Callback when polyline position changes.
  final void Function(LatLng oldPos, LatLng newPos)? onPositionChanged;

  GesturePolylineOptions copyWith({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onHover,
    void Function(LatLng oldPos, LatLng newPos)? onPositionChanged,
  }) {
    return GesturePolylineOptions(
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onHover: onHover ?? this.onHover,
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GesturePolylineOptions && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
