import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/entity_logic.dart';
import 'package:flutter_map_interactive/common/options.dart';
import 'package:flutter_map_interactive/overlays/controllers/op.dart';
import 'package:flutter_map_interactive/overlays/logic/overlay_logic.dart';
import 'package:flutter_map_interactive/overlays/models/interactive_overlay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../common/test_image.dart';

void main() {
  group('OverlayLogic', () {
    late OverlayLogic logic;
    late InteractiveOptions<InteractiveOverlayImage> options;

    setUp(() {
      options = const InteractiveOptions<InteractiveOverlayImage>();
      logic = OverlayLogic(() => options);
    });

    group('Key Management', () {
      test('getItemKey returns overlay key', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        expect(logic.getItemKey(overlay), const ValueKey('o1'));
      });

      test('ensureHasKey throws when key is missing', () {
        final overlay = InteractiveOverlayImage(
          image: kTestImage,
          corners: QuadLatLng(
            topLeft: const LatLng(10, 0),
            topRight: const LatLng(10, 10),
            bottomRight: const LatLng(0, 10),
            bottomLeft: const LatLng(0, 0),
          ),
        );

        expect(
          () => logic.ensureHasKey(overlay),
          throwsArgumentError,
        );
      });

      test('ensureHasKey does not throw when key exists', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        expect(
          () => logic.ensureHasKey(overlay),
          returnsNormally,
        );
      });
    });

    group('Spatial Change Detection', () {
      test('hasSpatialChange detects corner changes', () {
        final oldOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );
        final newOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(15, 5), // Changed
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        expect(logic.hasSpatialChange(oldOverlay, newOverlay), isTrue);
      });

      test('hasSpatialChange detects multiple corner changes', () {
        final oldOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );
        final newOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(20, 10),
          topRight: const LatLng(20, 20),
          bottomRight: const LatLng(10, 20),
          bottomLeft: const LatLng(10, 10),
        );

        expect(logic.hasSpatialChange(oldOverlay, newOverlay), isTrue);
      });

      test('hasSpatialChange returns false when corners identical', () {
        final oldOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );
        final newOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        expect(logic.hasSpatialChange(oldOverlay, newOverlay), isFalse);
      });

      test('hasSpatialChange ignores non-spatial changes', () {
        final oldOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
          alpha: 100,
        );
        final newOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
          alpha: 200, // Changed
        );

        expect(logic.hasSpatialChange(oldOverlay, newOverlay), isFalse);
      });
    });

    group('Operation Creation', () {
      test('createAddOp creates OverlayOp.add', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        final op = logic.createAddOp(overlay);

        expect(op, isA<OverlayOp>());
        final items = <InteractiveOverlayImage>[];
        op.apply(items);
        expect(items, contains(overlay));
      });

      test('createRemoveOp creates OverlayOp.remove', () {
        const key = ValueKey('o1');
        final op = logic.createRemoveOp(key);

        expect(op, isA<OverlayOp>());
      });

      test('createUpdateOp creates OverlayOp.update', () {
        final oldOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );
        final newOverlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(20, 10),
          topRight: const LatLng(20, 20),
          bottomRight: const LatLng(10, 20),
          bottomLeft: const LatLng(10, 10),
        );

        final op = logic.createUpdateOp(oldOverlay, newOverlay);

        expect(op, isA<OverlayOp>());
      });

      test('createDragEndOp translates all corners correctly', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );
        const origin = LatLng(5, 5);
        const current = LatLng(10, 10);

        final op = logic.createDragEndOp(overlay, origin, current);

        expect(op, isNotNull);
        expect(op, isA<OverlayOp>());

        // Verify the operation translates all corners
        final items = [overlay];
        op!.apply(items);

        final moved = items.first;
        // Delta: lat +5, lng +5
        expect(moved.corners.topLeft, const LatLng(15, 5));
        expect(moved.corners.topRight, const LatLng(15, 15));
        expect(moved.corners.bottomRight, const LatLng(5, 15));
        expect(moved.corners.bottomLeft, const LatLng(5, 5));
      });

      test('createDragEndOp preserves other properties', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
          alpha: 150,
        );
        const origin = LatLng(0, 0);
        const current = LatLng(5, 5);

        final op = logic.createDragEndOp(overlay, origin, current);

        final items = [overlay];
        op!.apply(items);

        final moved = items.first;
        expect(moved.alpha, 150);
        expect(moved.image, kTestImage);
      });

      test('createDragEndOp returns null when overlay has no key', () {
        final overlay = InteractiveOverlayImage(
          image: kTestImage,
          corners: QuadLatLng(
            topLeft: const LatLng(10, 0),
            topRight: const LatLng(10, 10),
            bottomRight: const LatLng(0, 10),
            bottomLeft: const LatLng(0, 0),
          ),
        );
        const origin = LatLng(0, 0);
        const current = LatLng(5, 5);

        final op = logic.createDragEndOp(overlay, origin, current);

        expect(op, isNull);
      });

      test('createDragEndOp handles zero delta', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );
        const origin = LatLng(0, 0);
        const current = LatLng(0, 0);

        final op = logic.createDragEndOp(overlay, origin, current);

        final items = [overlay];
        op!.apply(items);

        final moved = items.first;
        expect(moved.corners.topLeft, const LatLng(10, 0));
        expect(moved.corners.topRight, const LatLng(10, 10));
        expect(moved.corners.bottomRight, const LatLng(0, 10));
        expect(moved.corners.bottomLeft, const LatLng(0, 0));
      });
    });

    group('Interaction Callbacks', () {
      test('onInteraction does not throw', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        expect(
          () => logic.onInteraction(overlay, InteractionType.tap),
          returnsNormally,
        );
        expect(
          () => logic.onInteraction(overlay, InteractionType.hover),
          returnsNormally,
        );
        expect(
          () => logic.onInteraction(overlay, InteractionType.longPress),
          returnsNormally,
        );
        expect(
          () => logic.onInteraction(overlay, InteractionType.active),
          returnsNormally,
        );
      });
    });

    group('Drag Updates', () {
      test('onDragUpdate does not throw', () {
        final overlay = InteractiveOverlayImage.safe(
          key: const ValueKey('o1'),
          image: kTestImage,
          topLeft: const LatLng(10, 0),
          topRight: const LatLng(10, 10),
          bottomRight: const LatLng(0, 10),
          bottomLeft: const LatLng(0, 0),
        );

        expect(
          () => logic.onDragUpdate(
              overlay, const LatLng(0, 0), const LatLng(5, 5)),
          returnsNormally,
        );
      });
    });
  });
}
