import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/collision/grid.dart';
import 'package:flutter_map_interactive/common/collision/layout.dart';
import 'package:flutter_map_interactive/common/collision/options.dart';

export 'strategies/golden_strategy.dart';
export 'strategies/nearest_strategy.dart';
export 'strategies/orbit_strategy.dart';
export 'strategies/radial_fan_strategy.dart';
export 'strategies/spiral_strategy.dart';

abstract class CollisionStrategy {
  List<CollisionPlacement> place<T>({
    required MapCamera cam,
    required Size viewport,
    required List<CollisionNode<T>> nodes,
    required CollisionOptions options,
    required SpatialHashGrid grid,
    required Map<Key, Offset> previousOffsets,
  });
}
