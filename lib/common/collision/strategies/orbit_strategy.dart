import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_map_interactive/common/collision/strategies/helpers.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';

class OrbitStrategy implements CollisionStrategy {
  const OrbitStrategy({
    this.angleSteps = 24,
    this.radialSlack = 4.0,
    this.radialSteps = 1,
    this.hysteresisPx = 2.0,
    this.hysteresisAngleSteps = 2,
    this.minCover = 0.95,
    this.strictCollision = false,
  }) : assert(angleSteps >= 8);

  /// Number of angular samples on the orbit.
  final int angleSteps;

  /// Small allowed deviation around the nominal orbit radius.
  final double radialSlack;

  /// Number of radial steps on each side of nominal radius.
  final int radialSteps;

  /// Padding relaxation when reusing a previous placement.
  final double hysteresisPx;

  /// Number of neighboring angular slots treated as sticky around the previous angle.
  final int hysteresisAngleSteps;

  /// Coverage required inside slots.
  final double minCover;

  /// If true, fallback refuses colliding candidates.
  /// If false, it picks the least-bad orbital candidate even under pressure.
  final bool strictCollision;

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

    bool fitsBase({
      required Rect rect,
      required int mask,
      bool hysteresis = false,
    }) {
      final pad = hysteresis
          ? math.max(0.0, options.pad - hysteresisPx)
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

    bool fitsIn(
      Rect cand,
      int mask,
      List<Rect> slots, {
      bool hysteresis = false,
    }) {
      return fitsBase(rect: cand, mask: mask, hysteresis: hysteresis) &&
          insideSlotsOrMostly(cand, slots, minCover: minCover);
    }

    int angleIndexFromOffset(Offset o) {
      if (o.distanceSquared < 1e-9) return 0;
      final a = math.atan2(o.dy, o.dx);
      final t = (a + math.pi) / (2 * math.pi);
      return (t * angleSteps).round() % angleSteps;
    }

    Iterable<int> angularOrder(int start) sync* {
      yield start;
      for (int d = 1; d < angleSteps; d++) {
        final cw = (start + d) % angleSteps;
        final ccw = (start - d) % angleSteps;
        yield cw;
        yield ccw < 0 ? ccw + angleSteps : ccw;
      }
    }

    Iterable<double> radialOrder(double baseRadius) sync* {
      yield baseRadius;
      if (radialSlack <= 0 || radialSteps <= 0) return;
      final step = radialSlack / radialSteps;
      for (int i = 1; i <= radialSteps; i++) {
        yield math.max(0.0, baseRadius - i * step);
        yield baseRadius + i * step;
      }
    }

    double orbitRadiusFor(Rect base, Rect anchorRect) {
      final halfW = (base.width + anchorRect.width) * 0.5;
      final halfH = (base.height + anchorRect.height) * 0.5;
      return math.max(halfW, halfH) + options.anchorPad;
    }

    final placements = <CollisionPlacement>[];
    final placedRects = <Rect>[];

    for (final n in nodesIn) {
      final size = n.knownSize ?? options.defaultSize;
      final alignment = n.alignment;
      final margin = n.margin ?? EdgeInsets.zero;
      final rotate = n.rotate;
      final mask = n.collisionMask;

      final anchorPx = cam.latLngToScreenOffset(n.anchor);
      final base = overlayRect(
        origin: anchorPx,
        size: size,
        alignment: alignment * -1,
        mapRotationRad: cam.rotationRad,
        rotate: rotate,
        margin: margin,
      );

      final anchorRect = n.anchorRectPx ??
          Rect.fromCenter(center: anchorPx, width: 1, height: 1);

      final prev = previousOffsets[n.key] ?? Offset.zero;

      var outward = anchorPx - view.center;
      if (outward.distanceSquared < 1e-9) outward = const Offset(1, 0);

      final startIndex = prev.distanceSquared > 1e-9
          ? angleIndexFromOffset(prev)
          : angleIndexFromOffset(outward);

      final baseRadius = orbitRadiusFor(base, anchorRect);
      final slots = computeSlots(
        anchorRect,
        options.anchorPad,
        math.max(options.maxRadius, baseRadius + radialSlack),
      );

      Offset? bestOffset;
      Rect? bestRect;
      double bestScore = double.infinity;

      Offset? softOffset;
      Rect? softRect;
      double softScore = double.infinity;

      void consider(
        Offset off,
        Rect cand, {
        required bool hard,
        required bool hysteresis,
      }) {
        final inSlots = insideSlotsOrMostly(cand, slots, minCover: minCover);
        if (!inSlots) return;

        final hardFits = fitsIn(cand, mask, slots, hysteresis: hysteresis);

        final connectorEnd = connectorEntryPoint(cand, anchorPx);
        final score = placementScore(
          candidate: off,
          previous: prev,
          outward: outward,
          connectorStart: anchorPx,
          connectorEnd: connectorEnd,
          candidateRect: cand,
          slots: slots,
          obstacles: placedRects,
          previousWeight: 1.1,
          originWeight: 0.0,
          directionWeight: 5.0,
          lengthWeight: 0.02,
          slotCenterWeight: 10.0,
          connectorIntersectWeight: 120.0,
          connectorProximityWeight: 18.0,
          connectorAvoidDistance: 8.0,
        );

        if (hard && hardFits) {
          if (score < bestScore) {
            bestScore = score;
            bestOffset = off;
            bestRect = cand;
          }
        } else if (!strictCollision) {
          var penalty = score;

          if (!hardFits) {
            penalty += 200.0;
          }

          final l = cand.left - options.pad;
          final t = cand.top - options.pad;
          final r = cand.right + options.pad;
          final b = cand.bottom + options.pad;

          if (options.avoidCollisions &&
              grid.collides(l, t, r, b, mask: mask)) {
            penalty += 400.0;
          }

          if (penalty < softScore) {
            softScore = penalty;
            softOffset = off;
            softRect = cand;
          }
        }
      }

      // 1) Reuse previous placement if still acceptable.
      if (prev.distanceSquared > 1e-9) {
        final prevRect = base.shift(prev);
        if (fitsIn(prevRect, mask, slots, hysteresis: true)) {
          bestOffset = prev;
          bestRect = prevRect;
        }
      }

      // 2) Otherwise search on a thin orbit.
      if (bestOffset == null) {
        final order = angularOrder(startIndex).toList();

        for (final radius in radialOrder(baseRadius)) {
          for (int rank = 0; rank < order.length; rank++) {
            final i = order[rank];
            final a = (2 * math.pi) * (i / angleSteps);
            final off = Offset(radius * math.cos(a), radius * math.sin(a));
            final cand = base.shift(off);

            consider(
              off,
              cand,
              hard: true,
              hysteresis: rank <= hysteresisAngleSteps,
            );

            if (!strictCollision) {
              consider(
                off,
                cand,
                hard: false,
                hysteresis: false,
              );
            }
          }
        }
      }

      final chosenOffset = bestOffset ?? softOffset ?? (() {
        final ref = prev.distanceSquared > 1e-9 ? prev : outward;
        final d = ref.distance;
        if (d <= 1e-9) return Offset(baseRadius, 0);
        return ref / d * baseRadius;
      })();

      final rect = bestRect ?? softRect ?? base.shift(chosenOffset);

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
        offsetPx: chosenOffset,
        centerPx: Offset(c.dx, c.dy),
      ));
      placedRects.add(rect);
    }

    return placements;
  }
}
