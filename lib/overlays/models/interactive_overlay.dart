import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/overlays/models/options.dart';
import 'package:flutter_map_interactive/overlays/models/quad.dart';
import 'package:latlong2/latlong.dart' show LatLng;

export 'quad.dart';

/// Represents a single image overlay defined by 4 geographic corners.
class InteractiveOverlayImage {
  const InteractiveOverlayImage({
    this.key,
    required this.image,
    required this.corners,
    this.alpha = 220,
    this.handleSize,
    this.options = const [],
  });

  /// Creates an [InteractiveOverlayImage] performing checks on [options].
  ///
  /// Keeps named arguments for convenience, but stores them in [corners].
  factory InteractiveOverlayImage.safe({
    Key? key,
    required ImageProvider image,
    required LatLng topLeft,
    required LatLng topRight,
    required LatLng bottomRight,
    required LatLng bottomLeft,
    int alpha = 220,
    double? handleSize,
    List<OverlayOptions> options = const [],
  }) {
    _debugAssertNoDuplicateOptionTypes(options);
    return InteractiveOverlayImage(
      key: key,
      image: image,
      corners: QuadLatLng(
        topLeft: topLeft,
        topRight: topRight,
        bottomRight: bottomRight,
        bottomLeft: bottomLeft,
      ),
      alpha: alpha,
      handleSize: handleSize,
      options: List<OverlayOptions>.unmodifiable(options),
    );
  }

  final Key? key;
  final ImageProvider image;
  final QuadLatLng corners;
  final int alpha;
  final double? handleSize;
  final List<OverlayOptions> options;

  static InteractiveOverlayImage fromOverlay(
    OverlayImage overlay, {
    List<OverlayOptions> options = const [],
    double? handleSize,
  }) {
    return InteractiveOverlayImage.safe(
      key: overlay.key,
      image: overlay.imageProvider,
      topLeft: overlay.bounds.northWest,
      topRight: overlay.bounds.northEast,
      bottomRight: overlay.bounds.southEast,
      bottomLeft: overlay.bounds.southWest,
      alpha: (overlay.opacity * 255).round(),
      options: options,
      handleSize: handleSize,
    );
  }

  InteractiveOverlayImage copyWith({
    Key? key,
    ImageProvider? image,
    QuadLatLng? corners,
    int? alpha,
    double? handleSize,
    List<OverlayOptions>? options,
  }) {
    return InteractiveOverlayImage(
      key: key ?? this.key,
      image: image ?? this.image,
      corners: corners ?? this.corners,
      alpha: alpha ?? this.alpha,
      handleSize: handleSize ?? this.handleSize,
      options: List<OverlayOptions>.of(options ?? this.options),
    );
  }

  // Typed getters for options
  ActiveOverlayOptions? get activeOptions =>
      options.opt<ActiveOverlayOptions>();
  GestureOverlayOptions? get gestureOptions =>
      options.opt<GestureOverlayOptions>();
  PopupOverlayOptions? get popupOptions => options.opt<PopupOverlayOptions>();
  LabelOverlayOptions? get labelOptions => options.opt<LabelOverlayOptions>();
  ActionOverlayOptions? get actionOptions =>
      options.opt<ActionOverlayOptions>();

  /// Returns a copy of this overlay with the specified option [opt] added or updated.
  InteractiveOverlayImage withOption<T extends OverlayOptions>(T opt) =>
      copyWith(options: options.setOpt<T>(opt));

  /// Returns a copy of this overlay with the option of type [T] removed.
  InteractiveOverlayImage withoutOption<T extends OverlayOptions>() =>
      copyWith(options: options.removeOpt<T>());

  LatLng get center => corners.center;

  void ensureHasKey() {
    if (key == null) {
      throw ArgumentError('Overlay must have a non-null key.');
    }
  }

  @override
  bool operator ==(Object other) {
    return other is InteractiveOverlayImage &&
        runtimeType == other.runtimeType &&
        key == other.key &&
        corners == other.corners;
  }

  @override
  int get hashCode => Object.hash(runtimeType, key, corners);

  @override
  String toString() {
    return 'InteractiveOverlayImage(key: $key, corners: $corners)';
  }
}

extension IterableOverlayX on List<InteractiveOverlayImage> {
  int indexOfKey(Key? key) {
    if (key == null) {
      throw ArgumentError('Key cannot be null');
    }
    final idx = indexWhere((o) => o.key == key);
    if (idx < 0) {
      throw StateError('Overlay not found for key : $key');
    }
    return idx;
  }

  int tryIndexOfKey(Key? key) =>
      key == null ? -1 : indexWhere((o) => o.key == key);

  ({bool removed, int index, InteractiveOverlayImage? overlay}) removeAtKey(
      Key? key) {
    final idx = tryIndexOfKey(key);
    if (idx < 0) return (removed: false, index: idx, overlay: null);
    return (removed: true, index: idx, overlay: removeAt(idx));
  }

  InteractiveOverlayImage findByKey(Key? key) {
    final idx = indexOfKey(key);
    return this[idx];
  }

  InteractiveOverlayImage? findByKeyOrNull(Key? key) {
    if (key == null) return null;
    for (final o in this) {
      if (o.key == key) return o;
    }
    return null;
  }

  InteractiveOverlayImage updateByKey(
      Key? key, InteractiveOverlayImage newOverlay) {
    final idx = indexOfKey(key);
    this[idx] = newOverlay;
    return this[idx];
  }

  /// Équivalent de updatePointByKey pour overlay :
  /// met à jour un coin.
  InteractiveOverlayImage updateCornerByKey(
      Key? key, QuadCorner corner, LatLng latlng) {
    final idx = indexOfKey(key);
    final old = this[idx];
    this[idx] =
        old.copyWith(corners: old.corners.copyWithCorner(corner, latlng));
    return this[idx];
  }

  /// Optionnel mais pratique : update quad complet en une fois
  InteractiveOverlayImage updateQuadByKey(Key? key, QuadLatLng newCorners) {
    final idx = indexOfKey(key);
    final old = this[idx];
    this[idx] = old.copyWith(corners: newCorners);
    return this[idx];
  }
}

void _debugAssertNoDuplicateOptionTypes(List<OverlayOptions> options) {
  assert(() {
    final seen = <Type>{};
    for (final o in options) {
      final t = o.runtimeType;
      if (!seen.add(t)) {
        throw FlutterError('Duplicate OverlayOptions type detected: $t');
      }
    }
    return true;
  }());
}

extension OverlayOptionsListX on List<OverlayOptions> {
  T? opt<T extends OverlayOptions>() {
    for (final o in this) {
      if (o is T) return o;
    }
    return null;
  }

  List<OverlayOptions> setOpt<T extends OverlayOptions>(T value) {
    final out = List<OverlayOptions>.of(this);
    final i = out.indexWhere((o) => o is T);
    if (i >= 0) {
      out[i] = value;
    } else {
      out.add(value);
    }
    return out;
  }

  List<OverlayOptions> removeOpt<T extends OverlayOptions>() {
    final out = List<OverlayOptions>.of(this)..removeWhere((o) => o is T);
    return out;
  }
}

