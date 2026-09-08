import 'dart:math' as math;

import 'package:flutter/widgets.dart';

final Expando<bool> _inMobileLayerCache = Expando<bool>('inMobileLayer');

@pragma('vm:prefer-inline')
bool isInMobileLayer(BuildContext context) {
  final cached = _inMobileLayerCache[context];
  if (cached != null) return cached;

  bool found = false;
  context.visitAncestorElements((el) {
    if (el.widget.runtimeType.toString() == 'MobileLayerTransformer') {
      found = true;
      return false;
    }
    return true;
  });
  _inMobileLayerCache[context] = found;
  return found;
}

@pragma('vm:prefer-inline')
double _alignOffset(double size, double margin, double align) =>
    0.5 * size * (1 + align) + 0.5 * margin * align;

@pragma('vm:prefer-inline')
({
  Offset tl,
  Size size,
  Offset pivot,
  double ax,
  double ay,
  bool counter,
}) _computeFrame({
  required Offset origin,
  required Size size,
  required Alignment alignment,
  required double mapRotationRad,
  required bool rotate,
  EdgeInsets margin = EdgeInsets.zero,
}) {
  final ax = _alignOffset(size.width, margin.horizontal, alignment.x);
  final ay = _alignOffset(size.height, margin.vertical, alignment.y);

  final tl = Offset(origin.dx - ax, origin.dy - ay);
  final pivot = origin;

  final counter = !rotate && mapRotationRad.abs() > 1e-6;

  return (tl: tl, size: size, pivot: pivot, ax: ax, ay: ay, counter: counter);
}

Matrix4 overlayMatrix({
  required Offset origin,
  required Size size,
  required Alignment alignment,
  required bool rotate,
  double mapRotationRad = 0.0,
  EdgeInsets margin = EdgeInsets.zero,
  Offset pixelOffset = Offset.zero,
}) {
  final f = _computeFrame(
    origin: origin,
    size: size,
    alignment: alignment,
    mapRotationRad: mapRotationRad,
    rotate: rotate,
    margin: margin,
  );

  final m = Matrix4.identity();

  if (f.counter) {
    final c = math.cos(-mapRotationRad);
    final s = math.sin(-mapRotationRad);
    final dx = f.tl.dx + pixelOffset.dx;
    final dy = f.tl.dy + pixelOffset.dy;
    final ax = f.ax;
    final ay = f.ay;

    // Col 0
    m[0] = c;
    m[1] = s;
    // Col 1
    m[4] = -s;
    m[5] = c;
    // Col 3 (Translation)
    m[12] = ax * (1 - c) + ay * s + dx;
    m[13] = ay * (1 - c) - ax * s + dy;
  } else {
    m.translateByDouble(
      f.tl.dx + pixelOffset.dx,
      f.tl.dy + pixelOffset.dy,
      0.0,
      1.0,
    );
  }

  return m;
}

Rect overlayRect({
  required Offset origin,
  required Size size,
  required Alignment alignment,
  required bool rotate,
  double mapRotationRad = 0.0,
  EdgeInsets margin = EdgeInsets.zero,
  Offset pixelOffset = Offset.zero,
}) {
  final f = _computeFrame(
    origin: origin,
    size: size,
    alignment: alignment,
    mapRotationRad: mapRotationRad,
    rotate: rotate,
    margin: margin,
  );

  if (!f.counter) {
    return Rect.fromLTWH(f.tl.dx, f.tl.dy, f.size.width, f.size.height)
        .shift(pixelOffset);
  }

  final theta = -mapRotationRad;
  final c = math.cos(theta);
  final s = math.sin(theta);

  final cx0 = f.tl.dx + 0.5 * f.size.width;
  final cy0 = f.tl.dy + 0.5 * f.size.height;

  final dx = cx0 - f.pivot.dx;
  final dy = cy0 - f.pivot.dy;
  final cx = f.pivot.dx + dx * c - dy * s;
  final cy = f.pivot.dy + dx * s + dy * c;

  final ac = c.abs(), as_ = s.abs();
  final rx = 0.5 * (f.size.width * ac + f.size.height * as_);
  final ry = 0.5 * (f.size.width * as_ + f.size.height * ac);

  return Rect.fromLTRB(cx - rx, cy - ry, cx + rx, cy + ry).shift(pixelOffset);
}
