import 'package:flutter/material.dart';

/// Configuration for collision detection layout.
class CollisionOptions {
  const CollisionOptions({
    this.step = 16,
    this.maxRadius = 96,
    this.pad = 4,
    this.anchorPad = 4,
    this.avoidCollisions = true,
    this.drawConnectors = true,
    this.connectorColor = const Color(0x66000000),
    this.connectorStrokeWidth = 1.5,
    this.defaultSize = const Size(50, 50),
  });

  /// Step size for the collision grid in logical pixels.
  final double step;

  /// Maximum radius for label placement.
  final double maxRadius;

  /// Padding around each node.
  final double pad;

  /// Padding for anchor connections.
  final double anchorPad;

  /// Whether to enable collision avoidance.
  final bool avoidCollisions;

  /// Whether to draw connector lines from labels to anchors.
  final bool drawConnectors;

  /// Color for connector lines.
  final Color connectorColor;

  /// Stroke width for connector lines.
  final double connectorStrokeWidth;

  /// Default size for unmeasured nodes.
  final Size defaultSize;

  CollisionOptions copyWith({
    double? step,
    double? maxRadius,
    double? pad,
    double? anchorPad,
    bool? avoidCollisions,
    bool? drawConnectors,
    Color? connectorColor,
    double? connectorStrokeWidth,
    Size? defaultSize,
  }) {
    return CollisionOptions(
      step: step ?? this.step,
      maxRadius: maxRadius ?? this.maxRadius,
      pad: pad ?? this.pad,
      anchorPad: anchorPad ?? this.anchorPad,
      avoidCollisions: avoidCollisions ?? this.avoidCollisions,
      drawConnectors: drawConnectors ?? this.drawConnectors,
      connectorColor: connectorColor ?? this.connectorColor,
      connectorStrokeWidth: connectorStrokeWidth ?? this.connectorStrokeWidth,
      defaultSize: defaultSize ?? this.defaultSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollisionOptions &&
          runtimeType == other.runtimeType &&
          step == other.step &&
          maxRadius == other.maxRadius &&
          pad == other.pad &&
          anchorPad == other.anchorPad &&
          avoidCollisions == other.avoidCollisions &&
          drawConnectors == other.drawConnectors &&
          connectorColor == other.connectorColor &&
          connectorStrokeWidth == other.connectorStrokeWidth &&
          defaultSize == other.defaultSize;

  @override
  int get hashCode => Object.hash(
        step,
        maxRadius,
        pad,
        anchorPad,
        avoidCollisions,
        drawConnectors,
        connectorColor,
        connectorStrokeWidth,
        defaultSize,
      );
}
