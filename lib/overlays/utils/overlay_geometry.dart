import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:latlong2/latlong.dart';

const kDistance = Distance();

/// Calculates the screen-based rotate handle position.
LatLng calcRotateHandlePos(InteractiveOverlayImage o, MapCamera cam) {
  try {
    final topMid = o.corners.topMid;
    final pTop = cam.latLngToScreenOffset(topMid);

    // Vector of top edge
    final pTR = cam.latLngToScreenOffset(o.corners.topRight);
    final pTL = cam.latLngToScreenOffset(o.corners.topLeft);
    final dx = pTR.dx - pTL.dx;
    final dy = pTR.dy - pTL.dy;

    final len = dx * dx + dy * dy;
    // Avoid div by zero
    if (len < 0.001) {
      return kDistance.offset(o.center,
          kDistance.as(LengthUnit.Meter, o.center, o.corners.topLeft), 0);
    }

    final dist = math.sqrt(len);
    // Normal vector logic:
    // If (dx, dy) is vector from TL to TR.
    // 90 degrees CCW in screen coords (y down) corresponds to (dy, -dx).
    // Handle distance: 40px

    final px = pTop.dx + (dy / dist) * 40;
    final py = pTop.dy + (-dx / dist) * 40;

    return cam.screenOffsetToLatLng(Offset(px, py));
  } catch (e) {
    // Fallback if no camera (e.g. test)
    return kDistance.offset(o.center,
        kDistance.as(LengthUnit.Meter, o.center, o.corners.topLeft), 0);
  }
}
