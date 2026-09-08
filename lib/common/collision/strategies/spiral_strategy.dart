import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_map_interactive/common/collision/strategies/helpers.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';

/// A collision strategy that resolves marker overlaps by snapping them back
/// along a spiral path. This approach attempts to reposition markers in a
/// visually appealing spiral pattern, reducing overlap while maintaining
/// proximity to their original location.
///
/// Useful for map marker clustering or enhanced marker placement where
/// collisions may occur.
class SnapBackSpiralStrategy implements CollisionStrategy {
  const SnapBackSpiralStrategy({
    this.snapBack = 1.0,
    this.epsilon = 1e-3,
  });
  final double snapBack;
  final double epsilon;

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

    int prio(CollisionNode<T> n) {
      if (n.priority <= 1) return n.priority;
      final p = cam.latLngToScreenOffset(n.anchor);
      return 2 + ((p - view.center).distance ~/ 50);
    }

    final nodesIn = nodes.toList()
      ..sort((a, b) {
        final pa = prio(a), pb = prio(b);
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
      final l = rect.left - options.pad;
      final t = rect.top - options.pad;
      final r = rect.right + options.pad;
      final b = rect.bottom + options.pad;
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
        insideSlotsOrMostly(cand, slots, minCover: 1.0); // strict

    @pragma('vm:prefer-inline')
    Offset? spiralInSlot(
        Rect base, int mask, Rect slot, double step, double maxR) {
      // snapback zéro if empty and in slot
      if (insideSlotsOrMostly(base, [slot], minCover: 1.0) &&
          fitsBase(rect: base, mask: mask)) {
        return Offset.zero;
      }
      final maxK = (maxR / step).floor();
      for (int k = 1; k <= maxK; k++) {
        for (final d in ring(k, step)) {
          final off = d;
          final cand = base.shift(off);
          if (!slot.overlaps(cand)) continue;
          if (insideSlotsOrMostly(cand, [slot], minCover: 1.0) &&
              fitsBase(rect: cand, mask: mask)) {
            return off;
          }
        }
      }
      return null;
    }

    final placements = <CollisionPlacement>[];
    final placedRects = <Rect>[];

    for (final n in nodesIn) {
      final size = n.knownSize ?? options.defaultSize;
      final alignment = n.alignment;
      final margin = n.margin ?? EdgeInsets.zero;
      final rotate = n.rotate;

      final anchorPx = cam.latLngToScreenOffset(n.anchor);
      final base = overlayRect(
        origin: anchorPx,
        size: size,
        alignment: alignment * -1,
        mapRotationRad: cam.rotationRad,
        rotate: rotate,
        margin: margin,
      );

      final mask = n.collisionMask;
      final prevRaw = previousOffsets[n.key] ?? Offset.zero;
      final prev = clampRadius(prevRaw, options.maxRadius);

      // Ordered slot with prev (fallback outward)
      final dir = prev.distance > 1e-6 ? prev : (anchorPx - view.center);
      final anchorRect = n.anchorRectPx ?? base;
      final slots = sortSlotsByDir(
        computeSlots(anchorRect, options.anchorPad, options.maxRadius),
        anchorPx,
        dir,
      );

      Offset off;
      Rect rect;

      // Snapback
      if (fitsIn(base, mask, slots)) {
        final snapped = Offset.lerp(prev, Offset.zero, snapBack) ?? Offset.zero;
        off = (snapped.distanceSquared < epsilon) ? Offset.zero : snapped;
        rect = base.shift(off);
      } else {
        // Around prev in best slot and tohers
        Offset? found;
        Rect? bestRect;
        double bestScore = double.infinity;
        for (final s in slots) {
          final candidateOffset =
              spiralInSlot(base, mask, s, options.step, options.maxRadius);
          if (candidateOffset == null) continue;
          final candidateRect = base.shift(candidateOffset);
          final connectorEnd = connectorEntryPoint(candidateRect, anchorPx);
          final score = placementScore(
            candidate: candidateOffset,
            previous: prev,
            outward: dir,
            connectorStart: anchorPx,
            connectorEnd: connectorEnd,
            candidateRect: candidateRect,
            slots: slots,
            obstacles: placedRects,
          );
          if (score < bestScore) {
            bestScore = score;
            found = candidateOffset;
            bestRect = candidateRect;
          }
        }
        if (found != null) {
          off = found;
          rect = bestRect ?? base.shift(off);
        } else {
          // fallback
          off = Offset.zero;
          rect = base;
        }
      }

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
