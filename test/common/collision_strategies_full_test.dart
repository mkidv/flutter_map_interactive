import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';
import 'package:flutter_map_interactive/common/collision/painter.dart';
import 'package:flutter_map_interactive/common/collision/strategies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  late MapCamera camera;
  late SpatialHashGrid grid;
  const viewport = Size(800, 600);
  const options = CollisionOptions(
    step: 8,
    maxRadius: 60,
    pad: 2,
    anchorPad: 2,
  );

  setUp(() {
    camera = MapCamera(
      crs: const Epsg3857(),
      minZoom: 0,
      maxZoom: 20,
      center: const LatLng(48.8566, 2.3522),
      zoom: 14,
      rotation: 0,
      nonRotatedSize: viewport,
    );
    grid = SpatialHashGrid();
  });

  List<CollisionNode<String>> createTestNodes({int count = 5}) {
    return List.generate(count, (i) {
      // Clustered near Paris center
      final lat = 48.8566 + (i * 0.0001);
      final lng = 2.3522 + (i * 0.0001);
      return CollisionNode<String>(
        key: ValueKey('node_$i'),
        anchor: LatLng(lat, lng),
        knownSize: const Size(40, 20),
        data: 'item_$i',
      );
    });
  }

  group('StickyGoldenFanStrategy', () {
    test('handles empty and single node', () {
      const strategy = StickyGoldenFanStrategy();
      final empty = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: [],
        options: options,
        grid: grid,
        previousOffsets: {},
      );
      expect(empty, isEmpty);

      final single = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: createTestNodes(count: 1),
        options: options,
        grid: grid,
        previousOffsets: {},
      );
      expect(single.length, 1);
    });

    test('places multiple overlapping nodes with and without previous offsets',
        () {
      const strategy = StickyGoldenFanStrategy();
      final nodes = createTestNodes(count: 6);

      final initialPlacements = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {},
      );
      expect(initialPlacements.length, nodes.length);

      final previousOffsets = {
        for (final p in initialPlacements) p.key: p.offsetPx,
      };

      final updatedPlacements = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: previousOffsets,
      );
      expect(updatedPlacements.length, nodes.length);
    });
  });

  group('StickyNearestStrategy', () {
    test('places nodes with and without previous offsets', () {
      const strategy = StickyNearestStrategy(directions: 16);
      final nodes = createTestNodes();

      final placements = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {},
      );
      expect(placements.length, nodes.length);

      final previousOffsets = {
        for (final p in placements) p.key: p.offsetPx,
      };

      final updated = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: previousOffsets,
      );
      expect(updated.length, nodes.length);
    });
  });

  group('OrbitStrategy', () {
    test('places nodes with strictCollision true and false', () {
      const relaxed = OrbitStrategy();
      final nodes = createTestNodes();

      final relaxedPlacements = relaxed.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {},
      );
      expect(relaxedPlacements.length, nodes.length);

      const strict = OrbitStrategy(strictCollision: true);
      final strictPlacements = strict.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {
          for (final p in relaxedPlacements) p.key: p.offsetPx,
        },
      );
      expect(strictPlacements.length, nodes.length);
    });
  });

  group('SnapBackSpiralStrategy', () {
    test('places nodes in spiral pattern and respects previous offsets', () {
      const strategy = SnapBackSpiralStrategy();
      final nodes = createTestNodes();

      final placements = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {},
      );
      expect(placements.length, nodes.length);

      final updated = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {
          for (final p in placements) p.key: p.offsetPx,
        },
      );
      expect(updated.length, nodes.length);
    });
  });

  group('RadialFanStrategy', () {
    test('places nodes in radial fan pattern', () {
      const strategy = RadialFanStrategy();
      final nodes = createTestNodes(count: 4);

      final placements = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {},
      );
      expect(placements.length, nodes.length);
    });
  });

  group('ConnectorPainter', () {
    test('paints connectors with straight and curved styles, dashes, and dots',
        () {
      const strategy = StickyGoldenFanStrategy();
      final nodes = createTestNodes(count: 4);
      final placements = strategy.place(
        cam: camera,
        viewport: viewport,
        nodes: nodes,
        options: options,
        grid: grid,
        previousOffsets: {},
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Curved with dots and dashes
      final painter1 = ConnectorPainter(
        cam: camera,
        nodes: nodes,
        placements: placements,
        color: Colors.blue,
        strokeWidth: 2.0,
        defaultSize: const Size(40, 20),
        dashed: true,
        startDot: true,
        endDot: true,
      );
      painter1.paint(canvas, viewport);

      // Straight without halo
      final painter2 = ConnectorPainter(
        cam: camera,
        nodes: nodes,
        placements: placements,
        color: Colors.red,
        strokeWidth: 1.5,
        defaultSize: const Size(40, 20),
        style: ConnectorStyle.straight,
        halo: false,
      );
      painter2.paint(canvas, viewport);

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter1), isFalse);
    });
  });
}
