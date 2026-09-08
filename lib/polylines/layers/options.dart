import 'package:flutter/widgets.dart';

/// Options for the polyline layer.
class PolylineLayerOptions {
  const PolylineLayerOptions({
    this.debug = false,
  });

  /// Whether to show debug information.
  final bool debug;

  PolylineLayerOptions copyWith({bool? debug}) {
    return PolylineLayerOptions(debug: debug ?? this.debug);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolylineLayerOptions &&
          runtimeType == other.runtimeType &&
          debug == other.debug;

  @override
  int get hashCode => debug.hashCode;
}

/// Options for polyline editing handles.
class PolylineHandleOptions {
  const PolylineHandleOptions({
    this.size = 14.0,
    this.color = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFF2196F3),
    this.borderWidth = 2.0,
    this.activeColor = const Color(0xFF2196F3),
    this.activeBorderColor = const Color(0xFFFFFFFF),
    this.activeBorderWidth = 2.0,
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

  /// Factor to increase touch area.
  final double touchSizeFactor;

  PolylineHandleOptions copyWith({
    double? size,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    Color? activeColor,
    Color? activeBorderColor,
    double? activeBorderWidth,
    double? touchSizeFactor,
  }) {
    return PolylineHandleOptions(
      size: size ?? this.size,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      activeColor: activeColor ?? this.activeColor,
      activeBorderColor: activeBorderColor ?? this.activeBorderColor,
      activeBorderWidth: activeBorderWidth ?? this.activeBorderWidth,
      touchSizeFactor: touchSizeFactor ?? this.touchSizeFactor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolylineHandleOptions &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          color == other.color &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          activeColor == other.activeColor &&
          activeBorderColor == other.activeBorderColor &&
          activeBorderWidth == other.activeBorderWidth &&
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
        touchSizeFactor,
      );
}
