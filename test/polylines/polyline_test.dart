import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/polylines/models/interactive_polyline.dart';
import 'package:flutter_map_interactive/polylines/models/options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('InteractivePolyline', () {
    final points = [const LatLng(0, 0), const LatLng(10, 10)];

    test('safe factory validates options', () {
      expect(
        () => InteractivePolyline.safe(
          key: const ValueKey('p1'),
          points: points,
          options: [
            const PopupPolylineOptions(),
            const PopupPolylineOptions(),
          ],
        ),
        throwsA(isA<FlutterError>()),
      );
    });

    test('fromPolyline converts standard Polyline', () {
      final polyline =
          Polyline(points: points, strokeWidth: 5.0, color: Colors.red);
      final enhanced = InteractivePolyline.fromPolyline(polyline);

      expect(enhanced.points, points);
      expect(enhanced.strokeWidth, 5.0);
      expect(enhanced.color, Colors.red);
      expect(enhanced.key, isNotNull); // Should generate UniqueKey
    });

    test('copyWith modifies fields', () {
      final p1 = InteractivePolyline.safe(
        key: const ValueKey('p1'),
        points: points,
        strokeWidth: 2.0,
      );

      final p2 = p1.copyWith(strokeWidth: 10.0);
      expect(p2.strokeWidth, 10.0);
      expect(p2.key, p1.key);
      expect(p2.points, p1.points);
    });

    test('option management helpers', () {
      var p =
          InteractivePolyline.safe(key: const ValueKey('p1'), points: points);

      const opt = PopupPolylineOptions();
      p = p.withOption(opt);

      expect(p.popupOptions, opt);

      p = p.withoutOption<PopupPolylineOptions>();
      expect(p.popupOptions, isNull);
    });
  });
}
