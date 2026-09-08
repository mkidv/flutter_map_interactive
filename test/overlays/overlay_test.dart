import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_map_interactive/overlays/models/options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_image.dart';

void main() {
  group('InteractiveOverlayImage', () {
    const tl = LatLng(10, 0); // approx rect
    const tr = LatLng(10, 10);
    const br = LatLng(0, 10);
    const bl = LatLng(0, 0);

    test('safe factory validates options', () {
      expect(
        () => InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: tl,
          topRight: tr,
          bottomRight: br,
          bottomLeft: bl,
          options: [
            const PopupOverlayOptions(popup: SizedBox()),
            const PopupOverlayOptions(popup: SizedBox()),
          ],
        ),
        throwsA(isA<FlutterError>()),
      );
    });

    test('fromOverlay converts standard OverlayImage', () {
      final bounds = LatLngBounds(
          const LatLng(10, 0),
          const LatLng(
              0, 10)); // Corner definitions depend on bounds implementation
      final overlay = OverlayImage(
        bounds: bounds,
        imageProvider: kTestImage,
        key: const ValueKey('o1'),
        opacity: 0.5,
      );

      final enhanced = InteractiveOverlayImage.fromOverlay(overlay);

      expect(enhanced.key, const ValueKey('o1'));
      expect(enhanced.alpha, (0.5 * 255).round());
      // Check corners logic derived from bounds
      expect(enhanced.corners.topLeft, bounds.northWest);
      expect(enhanced.corners.bottomRight, bounds.southEast);
    });

    test('copyWith modifies fields', () {
      final o1 = InteractiveOverlayImage.safe(
        key: const ValueKey('1'),
        image: const AssetImage('1.png'),
        topLeft: tl,
        topRight: tr,
        bottomRight: br,
        bottomLeft: bl,
      );

      final o2 = o1.copyWith(alpha: 100);
      expect(o2.alpha, 100);
      expect(o2.key, o1.key);
    });

    test('update corner helpers', () {
      final o1 = InteractiveOverlayImage.safe(
        key: const ValueKey('1'),
        image: const AssetImage('1.png'),
        topLeft: tl,
        topRight: tr,
        bottomRight: br,
        bottomLeft: bl,
      );

      final o2 = o1.copyWith(
        corners:
            o1.corners.copyWithCorner(QuadCorner.topLeft, const LatLng(20, 20)),
      );

      expect(o2.corners.topLeft, const LatLng(20, 20));
      // Others unchanged
      expect(o2.corners.topRight, tr);
    });

    test('should store and retrieve options correctly', () {
      final overlay = InteractiveOverlayImage(
        image: kTestImage,
        corners: QuadLatLng(
          topLeft: tl,
          topRight: tr,
          bottomRight: br,
          bottomLeft: bl,
        ),
        options: const [
          ActiveOverlayOptions(showOutline: false),
          GestureOverlayOptions(),
          ActionOverlayOptions(action: SizedBox()),
        ],
      );

      expect(overlay.activeOptions, isNotNull);
      expect(overlay.activeOptions!.showOutline, isFalse);
      expect(overlay.gestureOptions, isNotNull);
      expect(overlay.actionOptions, isNotNull);
      expect(overlay.popupOptions, isNull);
    });

    test('copyWith should preserve options', () {
      final overlay = InteractiveOverlayImage(
        image: kTestImage,
        corners: QuadLatLng(
          topLeft: tl,
          topRight: tr,
          bottomRight: br,
          bottomLeft: bl,
        ),
        options: const [
          ActiveOverlayOptions(outlineWidth: 5.0),
        ],
      );

      final copy = overlay.copyWith(alpha: 100);

      expect(copy.alpha, 100);
      expect(copy.activeOptions!.outlineWidth, 5.0);
    });

    test('withOption / withoutOption should modify options', () {
      var overlay = InteractiveOverlayImage(
        image: kTestImage,
        corners: QuadLatLng(
          topLeft: tl,
          topRight: tr,
          bottomRight: br,
          bottomLeft: bl,
        ),
      );

      expect(overlay.activeOptions, isNull);

      // Add option
      overlay =
          overlay.withOption(const ActiveOverlayOptions(outlineWidth: 10.0));
      expect(overlay.activeOptions!.outlineWidth, 10.0);

      // Update option
      overlay =
          overlay.withOption(const ActiveOverlayOptions(outlineWidth: 20.0));
      expect(overlay.activeOptions!.outlineWidth, 20.0);

      // Remove option
      overlay = overlay.withoutOption<ActiveOverlayOptions>();
      expect(overlay.activeOptions, isNull);
    });

    test('fromOverlay with options', () {
      final origin = OverlayImage(
        bounds: LatLngBounds(const LatLng(10, 0), const LatLng(0, 10)),
        imageProvider: kTestImage,
        opacity: 0.5,
      );

      final enhanced = InteractiveOverlayImage.fromOverlay(
        origin,
        options: [const GestureOverlayOptions()],
      );

      expect(enhanced.corners.topLeft, origin.bounds.northWest);
      expect(enhanced.corners.bottomRight, origin.bounds.southEast);
      expect(enhanced.alpha, 128); // 0.5 * 255 rounded
      expect(enhanced.gestureOptions, isNotNull);
    });
  });

  group('QuadLatLng', () {
    test('contains check', () {
      // Simple square 0,0 to 10,10
      final quad = QuadLatLng(
        topLeft: const LatLng(10, 0),
        topRight: const LatLng(10, 10),
        bottomRight: const LatLng(0, 10),
        bottomLeft: const LatLng(0, 0),
      );

      expect(quad.contains(const LatLng(5, 5)), isTrue);
      expect(quad.contains(const LatLng(15, 5)), isFalse);
    });

    test('rotate around center', () {
      // Square 0,0 to 10,10. Center 5,5.
      // Rotate 90 deg clockwise (pi/2)
      // LatLng (Y, X) usually.
      // Center (5, 5).
      // TL (10, 0) relative to center is (+5, -5).
      // Rotated 90 deg?
      // Let's just check center invariance.

      final quad = QuadLatLng(
        topLeft: const LatLng(10, 0), // Y=10, X=0
        topRight: const LatLng(10, 10), // Y=10, X=10
        bottomRight: const LatLng(0, 10), // Y=0, X=10
        bottomLeft: const LatLng(0, 0), // Y=0, X=0
      );

      final rotated = quad.rotate(math.pi / 2);

      final center = quad.center;
      final newCenter = rotated.center;

      expect(newCenter.latitude, closeTo(center.latitude, 0.05));
      expect(newCenter.longitude, closeTo(center.longitude, 0.05));
    });
  });
}
