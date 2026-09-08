import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_map_interactive/common/collision/strategies/helpers.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';

/// Collision strategy that searches near the previous offset first.
class StickyNearestStrategy implements CollisionStrategy {
  const StickyNearestStrategy({
    this.directions = 24,
    this.radialStep,
    this.hysteresisPx = 2,
  }) : assert(directions >= 8 && directions <= 256);

  final int directions;
  final double? radialStep;
  final double hysteresisPx;

  @override
  List<CollisionPlacement> place<T>({
    required MapCamera cam,
    required Size viewport,
    required List<CollisionNode<T>> nodes,
    required CollisionOptions options,
    required SpatialHashGrid grid,
    required Map<Key, Offset> previousOffsets,
  }) {
    final view = Offset.zero & viewport;

    final nodesIn = nodes.toList()
      ..sort((a, b) {
        final pa = screenPriority(a, view.center, cam);
        final pb = screenPriority(b, view.center, cam);
        if (pa != pb) return pa - pb;
        return a.key.hashCode.compareTo(b.key.hashCode);
      });

    grid.clear();
    for (final n in nodesIn) {
      final ar = n.anchorRectPx;
      if (ar != null) {
        grid.add(
          ar.left - options.anchorPad,
          ar.top - options.anchorPad,
          ar.right + options.anchorPad,
          ar.bottom + options.anchorPad,
          category: CollisionLayerBits.anchor,
        );
      }
    }

    @pragma('vm:prefer-inline')
    bool fitsBase({required Rect rect, required int mask}) {
      final pad = math.max(0.0, options.pad - hysteresisPx);
      final l = rect.left - pad;
      final t = rect.top - pad;
      final r = rect.right + pad;
      final b = rect.bottom + pad;
      if (r <= view.left ||
          l >= view.right ||
          b <= view.top ||
          t >= view.bottom) {
        return false;
      }
      if (!options.avoidCollisions) return true;
      return !grid.collides(l, t, r, b, mask: mask);
    }

    @pragma('vm:prefer-inline')
    bool fitsIn(Rect cand, int mask, List<Rect> slots) =>
        fitsBase(rect: cand, mask: mask) &&
        insideSlotsOrMostly(cand, slots, minCover: 0.9);

    @pragma('vm:prefer-inline')
    Iterable<int> aroundStart(int start, int n) sync* {
      yield start;
      for (int k = 1; k < n; k++) {
        final a = (start + k) % n;
        final b = (start - k) % n;
        yield a;
        yield (b < 0) ? b + n : b;
      }
    }

    @pragma('vm:prefer-inline')
    int startIndexForVector(Offset v) {
      if (v.distanceSquared < 1e-6) return 0;
      final ang = math.atan2(v.dy, v.dx);
      final t = (ang + math.pi) / (2 * math.pi);
      return (t * directions).round() % directions;
    }

    final step = radialStep ?? options.step;
    final placements = <CollisionPlacement>[];
    final placedRects = <Rect>[];

    for (final n in nodesIn) {
      final size = n.knownSize ?? options.defaultSize;
      final align = n.alignment;
      final margin = n.margin ?? EdgeInsets.zero;
      final rotate = n.rotate;

      final anchorPx = cam.latLngToScreenOffset(n.anchor);
      final base = overlayRect(
        origin: anchorPx,
        size: size,
        alignment: align * -1,
        mapRotationRad: cam.rotationRad,
        rotate: rotate,
        margin: margin,
      );

      final mask = n.collisionMask;
      final prevRaw = previousOffsets[n.key] ?? Offset.zero;
      final prev = clampRadius(prevRaw, options.maxRadius);
      final outward = anchorPx - view.center;

      final dir = prev.distance > 1e-6 ? prev : outward;
      final anchorRect = n.anchorRectPx ?? base;
      final slots = sortSlotsByDir(
        computeSlots(anchorRect, options.anchorPad, options.maxRadius),
        anchorPx,
        dir,
      );
      final alignmentOffsets = candidateAlignmentOffsets(
        anchorPx: anchorPx,
        size: size,
        currentAlignment: align,
        margin: margin,
        rotate: rotate,
        mapRotationRad: cam.rotationRad,
      );

      Rect rect = base.shift(prev);
      if (fitsIn(rect, mask, slots)) {
        grid.add(
          rect.left - options.pad,
          rect.top - options.pad,
          rect.right + options.pad,
          rect.bottom + options.pad,
          category: n.category,
        );
        final c = rect.center;
        placements.add(CollisionPlacement(
          key: n.key,
          offsetPx: prev,
          centerPx: Offset(c.dx, c.dy),
        ));
        continue;
      }

      if (fitsIn(base, mask, slots)) {
        grid.add(
          base.left - options.pad,
          base.top - options.pad,
          base.right + options.pad,
          base.bottom + options.pad,
          category: n.category,
        );
        final c = base.center;
        placements.add(CollisionPlacement(
          key: n.key,
          offsetPx: Offset.zero,
          centerPx: Offset(c.dx, c.dy),
        ));
        continue;
      }

      Offset? chosen;
      Rect? chosenRect;
      double bestScore = double.infinity;

      void considerCandidate(Offset candidateOffset, Rect candidateRect) {
        final connectorEnd = connectorEntryPoint(candidateRect, anchorPx);
        final score = placementScore(
          candidate: candidateOffset,
          previous: prev,
          outward: outward,
          connectorStart: anchorPx,
          connectorEnd: connectorEnd,
          candidateRect: candidateRect,
          slots: slots,
          obstacles: placedRects,
        );
        if (score < bestScore) {
          bestScore = score;
          chosen = candidateOffset;
          chosenRect = candidateRect;
        }
      }

      for (final seedOffset in alignmentOffsets) {
        final candidateRect = base.shift(seedOffset);
        if (!fitsIn(candidateRect, mask, slots)) continue;
        considerCandidate(seedOffset, candidateRect);
      }

      final startPrev = startIndexForVector(prev);
      for (double r = step; r <= options.maxRadius; r += step) {
        for (final s in slots) {
          for (final i in aroundStart(startPrev, directions)) {
            final th = (2 * math.pi) * (i / directions);
            final off = prev + Offset(r * math.cos(th), r * math.sin(th));
            final cand = base.shift(off);
            if (!s.overlaps(cand)) continue;
            if (fitsIn(cand, mask, slots)) {
              considerCandidate(off, cand);
            }
          }
        }
      }

      if (chosen == null) {
        const startZero = 0;
        for (double r = step; r <= options.maxRadius; r += step) {
          for (final s in slots) {
            for (final i in aroundStart(startZero, directions)) {
              final th = (2 * math.pi) * (i / directions);
              final off = Offset(r * math.cos(th), r * math.sin(th));
              final cand = base.shift(off);
              if (!s.overlaps(cand)) continue;
              if (fitsIn(cand, mask, slots)) {
                considerCandidate(off, cand);
              }
            }
          }
        }
      }

      final off = chosen ?? prev;
      rect = chosenRect ?? base.shift(off);

      grid.add(
        rect.left - options.pad,
        rect.top - options.pad,
        rect.right + options.pad,
        rect.bottom + options.pad,
        category: n.category,
      );

      final c = rect.center;
      placements.add(CollisionPlacement(
        key: n.key,
        offsetPx: off,
        centerPx: Offset(c.dx, c.dy),
      ));
      placedRects.add(rect);
    }

    return placements;
  }
}
