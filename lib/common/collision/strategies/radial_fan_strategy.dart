import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_map_interactive/common/collision/strategies/helpers.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';

/// Collision strategy that samples a radial fan around the anchor.
class RadialFanStrategy implements CollisionStrategy {
  const RadialFanStrategy({
    this.hysteresisPx = 2.0,
  });

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
    bool fitsBase({
      required Rect rect,
      required int mask,
      bool hysteresis = false,
    }) {
      final pad = hysteresis
          ? (options.pad - hysteresisPx).clamp(0.0, options.pad)
          : options.pad;
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
    bool fitsIn(Rect cand, int mask, List<Rect> slots,
            {bool hysteresis = false}) =>
        fitsBase(rect: cand, mask: mask, hysteresis: hysteresis) &&
        insideSlotsOrMostly(cand, slots, minCover: 1.0);

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

      var outward = anchorPx - view.center;
      if (outward.distance < 1) outward = const Offset(1, 0);
      outward = outward / outward.distance;

      final anchorRect = n.anchorRectPx ?? base;
      final slots = sortSlotsByDir(
        computeSlots(anchorRect, options.anchorPad, options.maxRadius),
        anchorPx,
        outward,
      );
      final alignmentOffsets = candidateAlignmentOffsets(
        anchorPx: anchorPx,
        size: size,
        currentAlignment: alignment,
        margin: margin,
        rotate: rotate,
        mapRotationRad: cam.rotationRad,
      );

      Offset off = previousOffsets[n.key] ?? Offset.zero;
      Rect rect = base.shift(off);
      final mask = n.collisionMask;

      if (fitsIn(rect, mask, slots, hysteresis: true)) {
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
        continue;
      }

      if (!fitsIn(rect, mask, slots)) {
        off = Offset.zero;
        rect = base;
      }

      if (options.avoidCollisions && !fitsIn(rect, mask, slots)) {
        var placed = false;
        Offset? bestOffset;
        Rect? bestRect;
        double bestScore = double.infinity;

        void considerCandidate(Offset candidateOffset, Rect candidateRect) {
          final connectorEnd = connectorEntryPoint(candidateRect, anchorPx);
          final score = placementScore(
            candidate: candidateOffset,
            previous: previousOffsets[n.key] ?? Offset.zero,
            outward: outward,
            connectorStart: anchorPx,
            connectorEnd: connectorEnd,
            candidateRect: candidateRect,
            slots: slots,
            obstacles: placedRects,
          );
          if (score < bestScore) {
            bestScore = score;
            bestOffset = candidateOffset;
            bestRect = candidateRect;
          }
        }

        for (final seedOffset in alignmentOffsets) {
          final candidateRect = base.shift(seedOffset);
          if (!fitsIn(candidateRect, mask, slots)) continue;
          considerCandidate(seedOffset, candidateRect);
        }

        for (final delta in fans(outward, options.step, options.maxRadius)) {
          final cand = base.shift(delta);
          bool inSomeSlot = false;
          for (final s in slots) {
            if (s.overlaps(cand)) {
              inSomeSlot = true;
              break;
            }
          }
          if (!inSomeSlot) continue;

          if (fitsIn(cand, mask, slots)) {
            considerCandidate(delta, cand);
          }
        }
        if (bestOffset != null && bestRect != null) {
          rect = bestRect!;
          off = bestOffset!;
          placed = true;
        }
        if (!placed) {
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
