import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/utils/math.dart' as math_utils;

class QuadVerticesPainter extends CustomPainter {
  QuadVerticesPainter({
    required this.image,
    required this.tl,
    required this.tr,
    required this.br,
    required this.bl,
    required this.alpha,
    this.drawOutline = false,
    this.outlineColor = const Color(0xFF000000),
    this.outlineWidth = 2.0,
    this.filterQuality = FilterQuality.medium,
    this.glowColor = const Color(0xFFFFFFFF),
    required this.glow,
  });

  final ui.Image image;
  final Offset tl, tr, br, bl;
  final int alpha;
  final bool drawOutline;
  final Color outlineColor;
  final double outlineWidth;
  final FilterQuality filterQuality;
  final Color glowColor;
  final bool glow;

  static final Float32List _pos = Float32List(12);
  static final Float32List _tex = Float32List(12);
  static final Float64List _identityMatrix4 =
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

  @override
  void paint(Canvas canvas, Size size) {
    final area = math_utils.signedArea4(tl, tr, br, bl);
    if (area.abs() < 1e-3) return;

    // CW/CCW
    final a = area;
    final p0 = a >= 0 ? tl : tl;
    final p1 = a >= 0 ? tr : bl; // inversion if needed
    final p2 = a >= 0 ? br : br;
    final p3 = a >= 0 ? bl : tr;

    _pos[0] = p0.dx;
    _pos[1] = p0.dy;
    _pos[2] = p1.dx;
    _pos[3] = p1.dy;
    _pos[4] = p2.dx;
    _pos[5] = p2.dy;
    _pos[6] = p0.dx;
    _pos[7] = p0.dy;
    _pos[8] = p2.dx;
    _pos[9] = p2.dy;
    _pos[10] = p3.dx;
    _pos[11] = p3.dy;

    final w = image.width.toDouble(), h = image.height.toDouble();

    _tex[0] = 0;
    _tex[1] = 0;
    _tex[2] = w;
    _tex[3] = 0;
    _tex[4] = w;
    _tex[5] = h;
    _tex[6] = 0;
    _tex[7] = 0;
    _tex[8] = w;
    _tex[9] = h;
    _tex[10] = 0;
    _tex[11] = h;

    final vertices = ui.Vertices.raw(
      VertexMode.triangles,
      _pos,
      textureCoordinates: _tex,
    );

    final shader = ImageShader(
        image, TileMode.clamp, TileMode.clamp, _identityMatrix4,
        filterQuality: filterQuality);

    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true
      ..colorFilter =
          const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.modulate)
      ..color = Color(0xFFFFFFFF).withAlpha(alpha);

    final path = ui.Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawVertices(vertices, BlendMode.srcOver, paint);

    // Glow (hover)
    if (glow) {
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = glowColor.withAlpha(90)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.outer, 12);

      canvas.drawPath(path, glowPaint);
    }

    // Outline (active)
    if (drawOutline && outlineWidth > 0) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth
        ..isAntiAlias = true
        ..strokeJoin = StrokeJoin.round
        ..color = outlineColor;

      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant QuadVerticesPainter o) =>
      !identical(o.image, image) ||
      tl != o.tl ||
      tr != o.tr ||
      br != o.br ||
      bl != o.bl ||
      alpha != o.alpha ||
      drawOutline != o.drawOutline ||
      glow != o.glow;
}
