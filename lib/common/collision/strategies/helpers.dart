import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';
import 'package:flutter_map_interactive/utils/rect_ops.dart';

const double _kGoldenAngle = math.pi * (3 - 1.618033988749895);
const double _kClearanceTarget = 6.0;

@pragma('vm:prefer-inline')
Offset rot(Offset v, double a) {
  final c = math.cos(a);
  final s = math.sin(a);
  return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
}

@pragma('vm:prefer-inline')
Iterable<Offset> fans(Offset outward, double step, double maxR) sync* {
  final dirs = <Offset>[
    outward,
    rot(outward, 0.25 * math.pi),
    rot(outward, -0.25 * math.pi),
    rot(outward, 0.5 * math.pi),
    rot(outward, -0.5 * math.pi),
    -outward,
  ];
  for (double r = step; r <= maxR; r += step) {
    for (final d in dirs) {
      yield d * r;
    }
  }
}

/// Golden spiral sampling with good angular distribution.
@pragma('vm:prefer-inline')
Iterable<Offset> goldenSpiral({
  required double step,
  required double maxR,
  double? startAngle,
}) sync* {
  final int maxK = (maxR / step).ceil();
  double ang = startAngle ?? 0.0;
  for (int k = 1; k <= maxK; k++) {
    final r = k * step;
    yield Offset(r * math.cos(ang), r * math.sin(ang));
    ang += _kGoldenAngle;
  }
}

@pragma('vm:prefer-inline')
Iterable<Offset> ring(int k, double step) sync* {
  for (int i = -k; i <= k; i++) {
    yield Offset(i * step, -k * step);
    if (k != 0) yield Offset(i * step, k * step);
  }
  for (int j = -k + 1; j <= k - 1; j++) {
    yield Offset(-k * step, j * step);
    if (k != 0) yield Offset(k * step, j * step);
  }
}

@pragma('vm:prefer-inline')
Offset clampRadius(Offset o, double maxR) {
  final d2 = o.distanceSquared;
  if (d2 <= 1e-12) return o;
  final d = math.sqrt(d2);
  if (d <= maxR) return o;
  final s = maxR / d;
  return Offset(o.dx * s, o.dy * s);
}

@pragma('vm:prefer-inline')
List<Rect> computeSlots(Rect anchorRect, double anchorPad, double maxRadius) {
  final halo = anchorRect.inflate(maxRadius);
  final padded = anchorRect.inflate(anchorPad);
  return halo.minus(padded, epsilon: 0.5);
}

@pragma('vm:prefer-inline')
bool overlapsAnySlot(Rect cand, List<Rect> slots) {
  for (final s in slots) {
    if (s.overlaps(cand)) return true;
  }
  return false;
}

@pragma('vm:prefer-inline')
bool insideSlotsOrMostly(Rect cand, List<Rect> slots,
    {double minCover = 0.95}) {
  if (slots.isEmpty) return true;
  final total = cand.width * cand.height;
  if (total <= 0) return false;
  double covered = 0;
  for (final s in slots) {
    covered += cand.intersectionArea(s);
    if (covered >= minCover * total) return true;
  }
  return covered >= minCover * total;
}

@pragma('vm:prefer-inline')
List<Rect> sortSlotsByDir(List<Rect> slots, Offset anchorPx, Offset dir) {
  final nd = dir.distance > 1e-6 ? dir / dir.distance : const Offset(1, 0);

  double score(Rect r) {
    final c = r.center - anchorPx;
    final nc = c.distance > 1e-6 ? c / c.distance : Offset.zero;
    return nc.dx * nd.dx + nc.dy * nd.dy;
  }

  slots.sort((a, b) {
    final sa = score(a);
    final sb = score(b);
    if (sa != sb) return sb.compareTo(sa);
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    if (areaA != areaB) return areaB.compareTo(areaA);
    return a.hashCode.compareTo(b.hashCode);
  });
  return slots;
}

@pragma('vm:prefer-inline')
Offset dirOrFallback(Offset prev, Offset outward) {
  if (prev.distanceSquared > 1e-12) return prev;
  if (outward.distanceSquared > 1e-12) return outward;
  return const Offset(1, 0);
}

int screenPriority<T>(CollisionNode<T> node, Offset viewCenter, MapCamera cam) {
  if (node.priority <= 1) return node.priority;
  final p = cam.latLngToScreenOffset(node.anchor);
  return 2 + ((p - viewCenter).distance ~/ 50);
}

double _slotClearance(Rect rect, Rect slot) {
  if (!slot.overlaps(rect)) return -1;
  final overlap = rect.intersect(slot);
  if (overlap.width <= 0 || overlap.height <= 0) return -1;

  return math.min(
    math.min(overlap.left - slot.left, slot.right - overlap.right),
    math.min(overlap.top - slot.top, slot.bottom - overlap.bottom),
  );
}

double bestSlotClearance(Rect rect, List<Rect> slots) {
  var best = -1.0;
  for (final slot in slots) {
    final clearance = _slotClearance(rect, slot);
    if (clearance > best) best = clearance;
  }
  return best;
}

double slotCoverageRatio(Rect rect, List<Rect> slots) {
  final total = rect.width * rect.height;
  if (total <= 0) return 0;
  var covered = 0.0;
  for (final slot in slots) {
    covered += rect.intersectionArea(slot);
  }
  return (covered / total).clamp(0.0, 1.0);
}

double bestSlotCenterDistanceRatio(Rect rect, List<Rect> slots) {
  if (slots.isEmpty) return 0;

  final center = rect.center;
  double? best;
  for (final slot in slots) {
    if (!slot.overlaps(rect)) continue;
    final diagonal = math.max(slot.size.longestSide, 1.0);
    final normalized = (center - slot.center).distance / diagonal;
    if (best == null || normalized < best) best = normalized;
  }
  return best ?? 1.0;
}

List<Offset> candidateAlignmentOffsets({
  required Offset anchorPx,
  required Size size,
  required Alignment currentAlignment,
  required EdgeInsets margin,
  required bool rotate,
  required double mapRotationRad,
}) {
  final base = overlayRect(
    origin: anchorPx,
    size: size,
    alignment: currentAlignment * -1,
    mapRotationRad: mapRotationRad,
    rotate: rotate,
    margin: margin,
  );

  final alignments = <Alignment>[
    currentAlignment,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  final offsets = <Offset>[Offset.zero];

  for (final alignment in alignments) {
    final rect = overlayRect(
      origin: anchorPx,
      size: size,
      alignment: alignment * -1,
      mapRotationRad: mapRotationRad,
      rotate: rotate,
      margin: margin,
    );
    final offset = rect.topLeft - base.topLeft;
    final exists = offsets.any((value) => (value - offset).distanceSquared < 0.5);
    if (!exists) offsets.add(offset);
  }

  return offsets;
}

@pragma('vm:prefer-inline')
Offset connectorEntryPoint(Rect rect, Offset anchor) {
  final from = rect.center;
  final vector = anchor - from;
  final vx = vector.dx;
  final vy = vector.dy;
  if (vx.abs() < 1e-6 && vy.abs() < 1e-6) return rect.center;

  double? bestT;

  if (vx != 0) {
    for (final x in [rect.left, rect.right]) {
      final t = (x - from.dx) / vx;
      final y = from.dy + t * vy;
      if (t > 0 && y >= rect.top - 1e-6 && y <= rect.bottom + 1e-6) {
        if (bestT == null || t < bestT) bestT = t;
      }
    }
  }

  if (vy != 0) {
    for (final y in [rect.top, rect.bottom]) {
      final t = (y - from.dy) / vy;
      final x = from.dx + t * vx;
      if (t > 0 && x >= rect.left - 1e-6 && x <= rect.right + 1e-6) {
        if (bestT == null || t < bestT) bestT = t;
      }
    }
  }

  return bestT == null ? rect.center : from + vector * bestT;
}

double _distancePointToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (ab2 <= 1e-12) return (p - a).distance;
  final ap = p - a;
  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / ab2).clamp(0.0, 1.0);
  final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - proj).distance;
}

double _orientation(Offset a, Offset b, Offset c) =>
    (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);

bool _onSegment(Offset a, Offset b, Offset p) =>
    p.dx >= math.min(a.dx, b.dx) - 1e-6 &&
    p.dx <= math.max(a.dx, b.dx) + 1e-6 &&
    p.dy >= math.min(a.dy, b.dy) - 1e-6 &&
    p.dy <= math.max(a.dy, b.dy) + 1e-6;

bool _segmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
  final o1 = _orientation(a1, a2, b1);
  final o2 = _orientation(a1, a2, b2);
  final o3 = _orientation(b1, b2, a1);
  final o4 = _orientation(b1, b2, a2);

  if ((o1 > 0) != (o2 > 0) && (o3 > 0) != (o4 > 0)) return true;

  if (o1.abs() <= 1e-6 && _onSegment(a1, a2, b1)) return true;
  if (o2.abs() <= 1e-6 && _onSegment(a1, a2, b2)) return true;
  if (o3.abs() <= 1e-6 && _onSegment(b1, b2, a1)) return true;
  if (o4.abs() <= 1e-6 && _onSegment(b1, b2, a2)) return true;

  return false;
}

bool segmentIntersectsRect(Offset a, Offset b, Rect rect) {
  if (rect.contains(a) || rect.contains(b)) return true;
  final tl = rect.topLeft;
  final tr = rect.topRight;
  final bl = rect.bottomLeft;
  final br = rect.bottomRight;
  return _segmentsIntersect(a, b, tl, tr) ||
      _segmentsIntersect(a, b, tr, br) ||
      _segmentsIntersect(a, b, br, bl) ||
      _segmentsIntersect(a, b, bl, tl);
}

double segmentDistanceToRect(Offset a, Offset b, Rect rect) {
  if (segmentIntersectsRect(a, b, rect)) return 0.0;
  final corners = [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight];
  var best = double.infinity;
  for (final corner in corners) {
    final d = _distancePointToSegment(corner, a, b);
    if (d < best) best = d;
  }
  return best;
}

double connectorObstaclePenalty(
  Offset start,
  Offset end,
  List<Rect> obstacles, {
  double avoidDistance = 10.0,
  double intersectWeight = 160.0,
  double proximityWeight = 24.0,
}) {
  var penalty = 0.0;
  for (final obstacle in obstacles) {
    final distance = segmentDistanceToRect(start, end, obstacle);
    if (distance <= 0.0) {
      penalty += intersectWeight;
      continue;
    }
    if (distance < avoidDistance) {
      penalty += (1 - distance / avoidDistance) * proximityWeight;
    }
  }
  return penalty;
}

double placementScore({
  required Offset candidate,
  required Offset previous,
  required Offset outward,
  Offset? connectorStart,
  Offset? connectorEnd,
  Rect? candidateRect,
  List<Rect> slots = const [],
  List<Rect> obstacles = const [],
  double previousWeight = 0.65,
  double originWeight = 0.2,
  double directionWeight = 16.0,
  double lengthWeight = 0.18,
  double clearanceWeight = 8.0,
  double coverageWeight = 16.0,
  double slotCenterWeight = 18.0,
  double connectorIntersectWeight = 160.0,
  double connectorProximityWeight = 24.0,
  double connectorAvoidDistance = 10.0,
}) {
  final prevDistance = (candidate - previous).distance;
  final originDistance = candidate.distance;
  final connectorLength = candidate.distance;

  final preferredDir = dirOrFallback(previous, outward);
  final preferredNorm = preferredDir.distance > 1e-6
      ? preferredDir / preferredDir.distance
      : const Offset(1, 0);
  final candidateNorm = candidate.distance > 1e-6
      ? candidate / candidate.distance
      : Offset.zero;
  final directionPenalty =
      (1 -
              (candidateNorm.dx * preferredNorm.dx +
                  candidateNorm.dy * preferredNorm.dy)) *
          directionWeight;

  final clearancePenalty = switch (candidateRect) {
    final Rect rect when slots.isNotEmpty =>
      math.max(0.0, _kClearanceTarget - bestSlotClearance(rect, slots)) *
          clearanceWeight,
    _ => 0.0,
  };

  final coveragePenalty = switch (candidateRect) {
    final Rect rect when slots.isNotEmpty =>
      (1 - slotCoverageRatio(rect, slots)) * coverageWeight,
    _ => 0.0,
  };

  final slotCenterPenalty = switch (candidateRect) {
    final Rect rect when slots.isNotEmpty =>
      bestSlotCenterDistanceRatio(rect, slots) * slotCenterWeight,
    _ => 0.0,
  };

  final connectorPenalty = switch ((connectorStart, connectorEnd)) {
    (final Offset start, final Offset end) when obstacles.isNotEmpty =>
      connectorObstaclePenalty(
        start,
        end,
        obstacles,
        avoidDistance: connectorAvoidDistance,
        intersectWeight: connectorIntersectWeight,
        proximityWeight: connectorProximityWeight,
      ),
    _ => 0.0,
  };

  return prevDistance * previousWeight +
      originDistance * originWeight +
      connectorLength * lengthWeight +
      directionPenalty +
      clearancePenalty +
      coveragePenalty +
      slotCenterPenalty +
      connectorPenalty;
}
