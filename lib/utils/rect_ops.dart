import 'dart:math' as math;
import 'dart:ui';

extension RectOps on Rect {
  List<Rect> xor(Rect other, {double epsilon = 0.0}) {
    if (!overlaps(other)) return [this, other];
    final a = minus(other, epsilon: epsilon);
    final b = other.minus(this, epsilon: epsilon);
    return [...a, ...b];
  }

  List<Rect> minus(Rect other, {double epsilon = 0.0}) {
    final i = intersection(other);
    if (i == null) return [this];

    final out = <Rect>[];

    Rect? rectOrNull(double l, double t, double r, double b) =>
        ((r - l) <= epsilon || (b - t) <= epsilon)
            ? null
            : Rect.fromLTRB(l, t, r, b);

    final top = rectOrNull(left, topLeft.dy, right, i.top);
    final bottom = rectOrNull(left, i.bottom, right, bottomRight.dy);

    final leftBand = rectOrNull(left, i.top, i.left, i.bottom);
    final rightBand = rectOrNull(i.right, i.top, right, i.bottom);

    if (top != null) out.add(top);
    if (bottom != null) out.add(bottom);
    if (leftBand != null) out.add(leftBand);
    if (rightBand != null) out.add(rightBand);

    return out;
  }

  Rect? intersection(Rect other) {
    if (!overlaps(other)) return null;
    final l = math.max(left, other.left);
    final r = math.min(right, other.right);
    final t = math.max(top, other.top);
    final b = math.min(bottom, other.bottom);
    return (r > l && b > t) ? Rect.fromLTRB(l, t, r, b) : null;
  }

  double intersectionArea(Rect other) {
    final i = intersection(other);
    return i == null ? 0.0 : i.width * i.height;
  }
}

/// Calculates the offset needed to move [rect] inside [safeArea].
@pragma('vm:prefer-inline')
Offset getPanCorrection(Rect rect, Rect safeArea) {
  double ox = 0, oy = 0;

  if (rect.left < safeArea.left) {
    ox = safeArea.left - rect.left;
  } else if (rect.right > safeArea.right) {
    ox = safeArea.right - rect.right;
  }

  if (rect.top < safeArea.top) {
    oy = safeArea.top - rect.top;
  } else if (rect.bottom > safeArea.bottom) {
    oy = safeArea.bottom - rect.bottom;
  }

  return Offset(ox, oy);
}

/// Calculates the bounding box of a collection of [Offset]s.
@pragma('vm:prefer-inline')
Rect getBounds(Iterable<Offset> points) {
  if (points.isEmpty) return Rect.zero;
  double minX = double.infinity, maxX = double.negativeInfinity;
  double minY = double.infinity, maxY = double.negativeInfinity;
  for (final p in points) {
    minX = math.min(minX, p.dx);
    maxX = math.max(maxX, p.dx);
    minY = math.min(minY, p.dy);
    maxY = math.max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
