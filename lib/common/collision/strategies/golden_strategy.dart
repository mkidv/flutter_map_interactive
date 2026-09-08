import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_map_interactive/common/collision/strategies/helpers.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';

/// Stable collision strategy with a bounded search budget.
///
/// Pipeline:
/// 1) Keep previous offset if valid (hysteresis)
/// 2) Golden spiral around `prev`
/// 3) Golden spiral around 0 (snapback)
/// 4) Mini conical fan around the `dir` vector
/// 5) Fail-safe: `prev` (or zero)
///
/// Key parameters:
/// - hysteresisPx: reduces pad during check to stabilize existing placement
/// - minCover: tolerance for inclusion in slots (0.9–0.95 recommended)
/// - fanDirs / fanConeRad: short cone as last resort
class StickyGoldenFanStrategy implements CollisionStrategy {
  const StickyGoldenFanStrategy({
    this.hysteresisPx = 2.0,
    this.minCover = 0.92,
    this.fanDirs = 16,
    this.fanConeRad = math.pi / 3, // 60°
  });
  final double hysteresisPx;
  final double minCover;
  final int fanDirs;
  final double fanConeRad;

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

    // Stable ordering
    final nodesIn = nodes.toList()
      ..sort((a, b) {
        final pa = screenPriority(a, view.center, cam);
        final pb = screenPriority(b, view.center, cam);
        if (pa != pb) return pa - pb;
        return a.key.hashCode.compareTo(b.key.hashCode);
      });

    // Index anchors
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

    // --- local helpers (inlined) ---

    @pragma('vm:prefer-inline')
    bool fitsBase({
      required Rect rect,
      required int mask,
      required bool hysteresis,
    }) {
      // effective pad with hysteresis
      final padEff =
          math.max(0.0, options.pad - (hysteresis ? hysteresisPx : 0.0));
      final l = rect.left - padEff;
      final t = rect.top - padEff;
      final r = rect.right + padEff;
      final b = rect.bottom + padEff;
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
        {bool hysteresis = false}) {
      return fitsBase(rect: cand, mask: mask, hysteresis: hysteresis) &&
          insideSlotsOrMostly(cand, slots, minCover: minCover);
    }

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

      var outward = anchorPx - view.center;
      if (outward.distance < 1.0) outward = const Offset(1, 0);
      outward = outward / outward.distance;

      final dir = dirOrFallback(prev, outward);

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

      Offset off = prev;
      Rect rect = base.shift(off);

      if (!fitsIn(rect, mask, slots, hysteresis: true)) {
        off = Offset.zero;
        rect = base;
      }

      if (options.avoidCollisions && !fitsIn(rect, mask, slots)) {
        final startAngPrev = (prev.distanceSquared > 1e-12)
            ? math.atan2(prev.dy, prev.dx)
            : math.atan2(outward.dy, outward.dx);

        bool placed = false;
        Offset? bestOffset;
        Rect? bestRect;
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
            bestOffset = candidateOffset;
            bestRect = candidateRect;
          }
        }

        for (final seedOffset in alignmentOffsets) {
          final candidateRect = base.shift(seedOffset);
          if (!fitsIn(candidateRect, mask, slots)) continue;
          considerCandidate(seedOffset, candidateRect);
        }

        for (final p in goldenSpiral(
          step: options.step,
          maxR: options.maxRadius,
          startAngle: startAngPrev,
        )) {
          final cand = base.shift(p);
          if (!overlapsAnySlot(cand, slots)) continue;
          if (fitsIn(cand, mask, slots)) {
            considerCandidate(p, cand);
          }
        }

        if (bestOffset != null && bestRect != null) {
          off = bestOffset!;
          rect = bestRect!;
          placed = true;
        }

        if (!placed) {
          final startAngZero = math.atan2(outward.dy, outward.dx);
          for (final p in goldenSpiral(
            step: options.step,
            maxR: options.maxRadius,
            startAngle: startAngZero,
          )) {
            final cand = base.shift(p);
            if (!overlapsAnySlot(cand, slots)) continue;
            if (fitsIn(cand, mask, slots)) {
              considerCandidate(p, cand);
            }
          }

          if (bestOffset != null && bestRect != null) {
            off = bestOffset!;
            rect = bestRect!;
            placed = true;
          }
        }

        if (!placed && fanDirs > 0 && fanConeRad > 0) {
          final baseAng = math.atan2(dir.dy, dir.dx);
          for (int i = 0; i < fanDirs; i++) {
            final a = -fanConeRad / 2 + fanConeRad * (i / (fanDirs - 1));
            final ang = baseAng + a;
            for (double r = options.step;
                r <= options.maxRadius;
                r += options.step) {
              final p = Offset(r * math.cos(ang), r * math.sin(ang));
              final cand = base.shift(p);
              if (!overlapsAnySlot(cand, slots)) continue;
              if (fitsIn(cand, mask, slots)) {
                considerCandidate(p, cand);
              }
            }
          }

          if (bestOffset != null && bestRect != null) {
            off = bestOffset!;
            rect = bestRect!;
            placed = true;
          }
        }

        if (!placed) {
          off = prev;
          rect = base.shift(off);
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
