import 'dart:math' as math;
import 'dart:ui';

import 'package:latlong2/latlong.dart';

/// Calculates the signed area of a polygon defined by [poly].
@pragma('vm:prefer-inline')
double signedArea(List<Offset> poly) {
  double a = 0;
  for (var i = 0; i < poly.length; i++) {
    final p = poly[i], q = poly[(i + 1) % poly.length];
    a += p.dx * q.dy - q.dx * p.dy;
  }
  return 0.5 * a;
}

/// Checks if point [p] is inside the triangle defined by [a], [b], [c].
@pragma('vm:prefer-inline')
bool pointInTri(Offset p, Offset a, Offset b, Offset c) {
  final v0 = c - a, v1 = b - a, v2 = p - a;
  final d00 = v0.dx * v0.dx + v0.dy * v0.dy;
  final d01 = v0.dx * v1.dx + v0.dy * v1.dy;
  final d11 = v1.dx * v1.dx + v1.dy * v1.dy;
  final d20 = v2.dx * v0.dx + v2.dy * v0.dy;
  final d21 = v2.dx * v1.dx + v2.dy * v1.dy;
  final denom = d00 * d11 - d01 * d01;
  if (denom.abs() < 1e-6) return false;
  final v = (d11 * d20 - d01 * d21) / denom;
  final w = (d00 * d21 - d01 * d20) / denom;
  final u = 1 - v - w;
  return u >= 0 && v >= 0 && w >= 0;
}

/// Checks if point [p] is inside the quad defined by [q] (must be 4 points).
@pragma('vm:prefer-inline')
bool pointInQuad(Offset p, List<Offset> q) {
  assert(q.length >= 4, 'Quad must have at least 4 points');
  return pointInTri(p, q[0], q[1], q[2]) || pointInTri(p, q[0], q[2], q[3]);
}

/// Checks if point [p] is inside the quad defined by [p1], [p2], [p3], [p4].
/// Optimized version without list allocation.
@pragma('vm:prefer-inline')
bool pointInQuad4(Offset p, Offset p1, Offset p2, Offset p3, Offset p4) {
  return pointInTri(p, p1, p2, p3) || pointInTri(p, p1, p3, p4);
}

/// Calculates the signed area of a 4-point polygon (quad).
/// Optimized version without list allocation.
@pragma('vm:prefer-inline')
double signedArea4(Offset p1, Offset p2, Offset p3, Offset p4) {
  return 0.5 *
      ((p1.dx * p2.dy - p2.dx * p1.dy) +
          (p2.dx * p3.dy - p3.dx * p2.dy) +
          (p3.dx * p4.dy - p4.dx * p3.dy) +
          (p4.dx * p1.dy - p1.dx * p4.dy));
}

/// Calculates the shortest distance from point [p] to the segment [v]-[w].
@pragma('vm:prefer-inline')
double distToSegment(Offset p, Offset v, Offset w) {
  final l2 = (v - w).distanceSquared;
  if (l2 == 0) return (p - v).distance;
  final t = ((p - v).dx * (w - v).dx + (p - v).dy * (w - v).dy) / l2;
  // Clamping t to [0,1] ensures we find distance to segment, not line
  final clampedT = math.max(0, math.min(1, t));
  final proj =
      Offset(v.dx + clampedT * (w - v).dx, v.dy + clampedT * (w - v).dy);
  return (p - proj).distance;
}

/// Snaps value [v] to the nearest multiple of [step].
@pragma('vm:prefer-inline')
double snap(double v, double step) => step <= 0 ? v : (v / step).round() * step;

/// Approximates meters per pixel at [lat] and [zoom].
@pragma('vm:prefer-inline')
double metersPerPixel(double lat, double zoom) {
  const earthCircumference = 40075016.686;
  final scale = math.cos(lat * math.pi / 180.0);
  return earthCircumference * scale / (256 * math.pow(2.0, zoom));
}

/// Calculates the centroid (average average) of a list of [LatLng]s.
LatLng centroid(Iterable<LatLng> points) {
  if (points.isEmpty) return const LatLng(0, 0);
  double lat = 0, lng = 0;
  int count = 0;
  for (final p in points) {
    lat += p.latitude;
    lng += p.longitude;
    count++;
  }
  return LatLng(lat / count, lng / count);
}
