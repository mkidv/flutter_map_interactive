import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/markers/models/options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('InteractiveMarker', () {
    const point = LatLng(0, 0);
    const child = SizedBox();

    test('safe factory prevents duplicate options', () {
      expect(
        () => InteractiveMarker.safe(
          point: point,
          child: child,
          options: [
            const PopupMarkerOptions(popup: SizedBox()),
            const PopupMarkerOptions(popup: SizedBox()),
          ],
        ),
        throwsA(isA<FlutterError>()),
      );
    });

    test('fromMarker converts standard marker', () {
      final marker = Marker(point: point, child: child);
      final enhanced = InteractiveMarker.fromMarker(marker);

      expect(enhanced.point, point);
      expect(enhanced.child, child);
      expect(enhanced.options, isEmpty);
    });

    test('fromMarker returns enhanced marker as is', () {
      final existing = InteractiveMarker(point: point, child: child);
      final cloned = InteractiveMarker.fromMarker(existing);
      expect(cloned, same(existing));
    });

    test('withOption adds or updates option', () {
      var marker = InteractiveMarker(point: point, child: child);

      const opt1 = PopupMarkerOptions(popup: SizedBox(width: 10));
      marker = marker.withOption(opt1);

      expect(marker.options, hasLength(1));
      expect(marker.popupOptions, opt1);

      const opt2 = PopupMarkerOptions(popup: SizedBox(width: 20));
      marker = marker.withOption(opt2);

      expect(marker.options, hasLength(1)); // Should replace
      expect(marker.popupOptions, opt2);
    });

    test('withoutOption removes option', () {
      var marker = InteractiveMarker(
        point: point,
        child: child,
        options: [const PopupMarkerOptions(popup: SizedBox())],
      );

      expect(marker.popupOptions, isNotNull);

      marker = marker.withoutOption<PopupMarkerOptions>();
      expect(marker.popupOptions, isNull);
      expect(marker.options, isEmpty);
    });

    test('equality checks', () {
      final m1 = InteractiveMarker(
          point: point, child: child, key: const ValueKey('1'));
      final m2 = InteractiveMarker(
          point: point, child: child, key: const ValueKey('1'));
      final m3 = InteractiveMarker(
          point: point, child: child, key: const ValueKey('2'));

      expect(m1, m2);
      expect(m1.hashCode, m2.hashCode);
      expect(m1, isNot(m3));
    });
  });

  group('MarkerOptions', () {
    test('PopupMarkerOptions defaults', () {
      const opt = PopupMarkerOptions(popup: SizedBox());
      expect(opt.alignment, Alignment.topCenter);
      expect(opt.rotate, isTrue);
    });

    test('LabelMarkerOptions defaults', () {
      const opt = LabelMarkerOptions(label: SizedBox());
      expect(opt.alignment, Alignment.bottomRight);
    });
  });
}
