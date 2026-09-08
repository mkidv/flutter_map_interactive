import 'package:flutter/widgets.dart';

/// Options for the overlay layer.
class OverlayLayerOptions {
  const OverlayLayerOptions({
    this.alpha = 255,
    this.filterQuality = FilterQuality.medium,
    this.zIndex = 0,
    this.showActiveOutline = true,
    this.activeOutlineColor = const Color(0xFF2196F3),
    this.activeOutlineWidth = 2.0,
  });

  /// Alpha transparency value (0-255).
  final int alpha;

  /// Filter quality for rendering.
  final FilterQuality filterQuality;

  /// Z-index for rendering order.
  final int zIndex;

  /// Whether to show outline when overlay is active.
  final bool showActiveOutline;

  /// Color of the active outline.
  final Color activeOutlineColor;

  /// Width of the active outline.
  final double activeOutlineWidth;

  OverlayLayerOptions copyWith({
    int? alpha,
    FilterQuality? filterQuality,
    int? zIndex,
    bool? showActiveOutline,
    Color? activeOutlineColor,
    double? activeOutlineWidth,
  }) {
    return OverlayLayerOptions(
      alpha: alpha ?? this.alpha,
      filterQuality: filterQuality ?? this.filterQuality,
      zIndex: zIndex ?? this.zIndex,
      showActiveOutline: showActiveOutline ?? this.showActiveOutline,
      activeOutlineColor: activeOutlineColor ?? this.activeOutlineColor,
      activeOutlineWidth: activeOutlineWidth ?? this.activeOutlineWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverlayLayerOptions &&
          runtimeType == other.runtimeType &&
          alpha == other.alpha &&
          filterQuality == other.filterQuality &&
          zIndex == other.zIndex &&
          showActiveOutline == other.showActiveOutline &&
          activeOutlineColor == other.activeOutlineColor &&
          activeOutlineWidth == other.activeOutlineWidth;

  @override
  int get hashCode => Object.hash(
        alpha,
        filterQuality,
        zIndex,
        showActiveOutline,
        activeOutlineColor,
        activeOutlineWidth,
      );
}

/// Options for overlay editing handles.
class OverlayHandleOptions {
  const OverlayHandleOptions({
    this.size = 20.0,
    this.color = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFF2196F3),
    this.borderWidth = 2.0,
    this.activeColor = const Color(0xFF2196F3),
    this.activeBorderColor = const Color(0xFFFFFFFF),
    this.activeBorderWidth = 2.0,
    this.connectorColor = const Color(0xE62196F3),
    this.connectorWidth = 1.5,
    this.touchSizeFactor = 1.5,
  });

  /// Size of the handle.
  final double size;

  /// Fill color of the handle.
  final Color color;

  /// Border color of the handle.
  final Color borderColor;

  /// Border width of the handle.
  final double borderWidth;

  /// Fill color when active/dragging.
  final Color activeColor;

  /// Border color when active/dragging.
  final Color activeBorderColor;

  /// Border width when active/dragging.
  final double activeBorderWidth;

  /// Color for connector lines between handles.
  final Color connectorColor;

  /// Width for connector lines.
  final double connectorWidth;

  /// Factor to increase touch area.
  final double touchSizeFactor;

  OverlayHandleOptions copyWith({
    double? size,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    Color? activeColor,
    Color? activeBorderColor,
    double? activeBorderWidth,
    Color? connectorColor,
    double? connectorWidth,
    double? touchSizeFactor,
  }) {
    return OverlayHandleOptions(
      size: size ?? this.size,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      activeColor: activeColor ?? this.activeColor,
      activeBorderColor: activeBorderColor ?? this.activeBorderColor,
      activeBorderWidth: activeBorderWidth ?? this.activeBorderWidth,
      connectorColor: connectorColor ?? this.connectorColor,
      connectorWidth: connectorWidth ?? this.connectorWidth,
      touchSizeFactor: touchSizeFactor ?? this.touchSizeFactor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverlayHandleOptions &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          color == other.color &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          activeColor == other.activeColor &&
          activeBorderColor == other.activeBorderColor &&
          activeBorderWidth == other.activeBorderWidth &&
          connectorColor == other.connectorColor &&
          connectorWidth == other.connectorWidth &&
          touchSizeFactor == other.touchSizeFactor;

  @override
  int get hashCode => Object.hash(
        size,
        color,
        borderColor,
        borderWidth,
        activeColor,
        activeBorderColor,
        activeBorderWidth,
        connectorColor,
        connectorWidth,
        touchSizeFactor,
      );
}
