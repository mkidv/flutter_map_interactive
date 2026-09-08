import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Base sealed class for all overlay options.
sealed class OverlayOptions {
  const OverlayOptions();
}

/// Options to configure the active state of an overlay.
class ActiveOverlayOptions extends OverlayOptions {
  const ActiveOverlayOptions({
    this.showOutline = true,
    this.outlineColor = const Color(0xFF2196F3),
    this.outlineWidth = 2.0,
  });

  /// Whether to show outline when active.
  final bool showOutline;

  /// Color of the outline.
  final Color outlineColor;

  /// Width of the outline.
  final double outlineWidth;

  ActiveOverlayOptions copyWith({
    bool? showOutline,
    Color? outlineColor,
    double? outlineWidth,
  }) {
    return ActiveOverlayOptions(
      showOutline: showOutline ?? this.showOutline,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveOverlayOptions &&
          runtimeType == other.runtimeType &&
          showOutline == other.showOutline &&
          outlineColor == other.outlineColor &&
          outlineWidth == other.outlineWidth;

  @override
  int get hashCode => Object.hash(showOutline, outlineColor, outlineWidth);
}

/// Options to configure specific gesture callbacks for an overlay.
class GestureOverlayOptions extends OverlayOptions {
  const GestureOverlayOptions({
    this.onTap,
    this.onLongPress,
    this.onHover,
    this.onPositionChanged,
  });

  /// Callback when overlay is tapped.
  final VoidCallback? onTap;

  /// Callback when overlay is long-pressed.
  final VoidCallback? onLongPress;

  /// Callback when overlay is hovered.
  final VoidCallback? onHover;

  /// Callback when overlay position changes.
  final void Function(LatLng oldPos, LatLng newPos)? onPositionChanged;

  GestureOverlayOptions copyWith({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onHover,
    void Function(LatLng oldPos, LatLng newPos)? onPositionChanged,
  }) {
    return GestureOverlayOptions(
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onHover: onHover ?? this.onHover,
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GestureOverlayOptions && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Options to configure a popup attached to an overlay.
class PopupOverlayOptions extends OverlayOptions {
  const PopupOverlayOptions({
    this.alignment = Alignment.topCenter,
    this.rotate = true,
    required this.popup,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
    this.margin,
  });

  /// Alignment of popup relative to overlay center.
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

  PopupOverlayOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Widget? popup,
    Duration? animationDuration,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return PopupOverlayOptions(
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
      other is PopupOverlayOptions &&
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

/// Options to configure a label attached to an overlay.
class LabelOverlayOptions extends OverlayOptions {
  const LabelOverlayOptions({
    this.alignment = Alignment.bottomRight,
    this.rotate = true,
    required this.label,
    this.hideOnEdit = false,
    this.margin,
  });

  /// Alignment of label relative to overlay.
  final Alignment alignment;

  /// Whether label should rotate with map.
  final bool rotate;

  /// The label widget.
  final Widget label;

  /// Whether to hide label in edit mode.
  final bool hideOnEdit;

  /// Margin around label.
  final EdgeInsets? margin;

  LabelOverlayOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Widget? label,
    bool? hideOnEdit,
    EdgeInsets? margin,
  }) {
    return LabelOverlayOptions(
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
      other is LabelOverlayOptions &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          rotate == other.rotate &&
          hideOnEdit == other.hideOnEdit &&
          margin == other.margin;

  @override
  int get hashCode => Object.hash(alignment, rotate, hideOnEdit, margin);
}

/// Options to configure an action widget attached to an overlay.
class ActionOverlayOptions extends OverlayOptions {
  const ActionOverlayOptions({
    this.alignment = Alignment.topRight,
    this.rotate = true,
    required this.action,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
    this.margin,
  });

  /// Alignment of action relative to overlay.
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

  ActionOverlayOptions copyWith({
    Alignment? alignment,
    bool? rotate,
    Widget? action,
    Duration? animationDuration,
    Curve? animationCurve,
    EdgeInsets? margin,
  }) {
    return ActionOverlayOptions(
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
      other is ActionOverlayOptions &&
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
