import 'package:flutter/material.dart';

import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/markers/models/options.dart';

/// A specialized [InteractiveMarker] used as a draggable handle for editing.
///
/// It provides default styling for normal and active states, with customization options.
class EditHandle extends InteractiveMarker {
  EditHandle({
    super.key,
    required super.point,
    required double size,
    IconData? icon,
    Color color = Colors.white,
    Color borderColor = const Color(0xFFE0E0E0),
    double borderWidth = 1.0,
    Color? iconColor,
    List<BoxShadow>? shadows,
    // Active state params
    Color? activeColor,
    Color? activeBorderColor,
    double? activeBorderWidth,
    double touchSizeFactor = 1.5,
    BoxShape shape = BoxShape.circle,
  }) : super(
          width: size,
          height: size,
          alignment: Alignment.center,
          rotate: false,
          // Normal State
          child: _HandleWidget(
            size: size,
            color: color,
            borderColor: borderColor,
            borderWidth: borderWidth,
            shape: shape,
            icon: icon,
            iconColor: iconColor ?? Colors.black54,
            shadows: shadows,
          ),
          options: [
            ActiveMarkerOptions(
              touchSizeFactor: touchSizeFactor,
              // Active State
              active: _HandleWidget(
                size: size,
                color: activeColor ?? color,
                borderColor: activeBorderColor ?? Colors.blueAccent,
                borderWidth: activeBorderWidth ?? 2.0,
                shape: shape,
                icon: icon,
                iconColor: iconColor ??
                    Colors.white, // Invert icon for active if needed
                shadows: [
                  BoxShadow(
                    color: (activeBorderColor ?? Colors.blueAccent)
                        .withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
                scale: 1.2, // Subtle scale up
              ),
            ),
          ],
        );
}

class _HandleWidget extends StatelessWidget {
  const _HandleWidget({
    required this.size,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.shape,
    this.icon,
    this.iconColor,
    this.shadows,
    this.scale = 1.0,
  });
  final double size;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final BoxShape shape;
  final IconData? icon;
  final Color? iconColor;
  final List<BoxShadow>? shadows;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: scale),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: shape,
              border: Border.all(color: borderColor, width: borderWidth),
              borderRadius:
                  shape == BoxShape.rectangle ? BorderRadius.circular(4) : null,
              boxShadow: shadows ??
                  const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
            ),
            child: icon != null
                ? Icon(
                    icon,
                    size: size * 0.6,
                    color: iconColor,
                  )
                : null,
          ),
        );
      },
    );
  }
}
