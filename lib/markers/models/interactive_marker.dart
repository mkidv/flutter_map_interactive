import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show Marker;
import 'package:flutter_map_interactive/markers/models/options.dart';
import 'package:latlong2/latlong.dart';

/// A specialized [Marker] that carries additional options for advanced features.
///
/// Use [options] to attach behavioral configurations like [LabelMarkerOptions],
/// [PopupMarkerOptions], [ActionMarkerOptions], etc.
class InteractiveMarker extends Marker {
  const InteractiveMarker({
    required super.point,
    required super.child,
    super.key,
    super.width = 30,
    super.height = 30,
    super.alignment,
    super.rotate,
    this.hidden = false,
    this.options = const [],
  });

  /// Creates an [InteractiveMarker] performing checks on [options].
  ///
  /// Throws an assertion error in debug mode if duplicate option types are detected.
  factory InteractiveMarker.safe({
    required LatLng point,
    required Widget child,
    Key? key,
    double width = 30,
    double height = 30,
    Alignment? alignment,
    bool? rotate,
    bool hidden = false,
    List<MarkerOptions> options = const [],
  }) {
    _debugAssertNoDuplicateOptionTypes(options);
    return InteractiveMarker(
      point: point,
      child: child,
      key: key,
      width: width,
      height: height,
      alignment: alignment,
      rotate: rotate,
      hidden: hidden,
      options: List<MarkerOptions>.unmodifiable(options),
    );
  }

  final bool hidden;

  /// List of options attached to this marker.
  final List<MarkerOptions> options;

  /// Converts a standard [Marker] to an [InteractiveMarker].
  ///
  /// If [marker] is already an [InteractiveMarker], it is returned as-is.
  /// Otherwise, a new [InteractiveMarker] is created with the same properties.
  static InteractiveMarker fromMarker(Marker marker) {
    return marker is InteractiveMarker
        ? marker
        : InteractiveMarker(
            key: marker.key,
            point: marker.point,
            child: marker.child,
            width: marker.width,
            height: marker.height,
            alignment: marker.alignment,
            rotate: marker.rotate,
          );
  }

  PopupMarkerOptions? get popupOptions => options.opt<PopupMarkerOptions>();
  LabelMarkerOptions? get labelOptions => options.opt<LabelMarkerOptions>();
  ActionMarkerOptions? get actionOptions => options.opt<ActionMarkerOptions>();
  GestureMarkerOptions? get gestureOptions =>
      options.opt<GestureMarkerOptions>();
  ActiveMarkerOptions? get activeOptions => options.opt<ActiveMarkerOptions>();
  bool get isHidden => hidden;

  /// Creates a copy of this marker with the given fields replaced with new values.
  InteractiveMarker copyWith({
    LatLng? point,
    Widget? child,
    double? width,
    double? height,
    Alignment? alignment,
    bool? rotate,
    bool? hidden,
    List<MarkerOptions>? options,
  }) {
    return InteractiveMarker(
      key: key,
      point: point ?? this.point,
      child: child ?? this.child,
      width: width ?? this.width,
      height: height ?? this.height,
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
      hidden: hidden ?? this.hidden,
      options: List<MarkerOptions>.of(options ?? this.options),
    );
  }

  /// Returns a copy of this marker with the specified option [opt] added or updated.
  InteractiveMarker withOption<T extends MarkerOptions>(T opt) =>
      copyWith(options: options.setOpt<T>(opt));

  /// Returns a copy of this marker with the option of type [T] removed.
  InteractiveMarker withoutOption<T extends MarkerOptions>() =>
      copyWith(options: options.removeOpt<T>());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveMarker &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          point == other.point &&
          hidden == other.hidden;

  @override
  int get hashCode => Object.hash(runtimeType, key, point, hidden);

  @override
  String toString() {
    return 'InteractiveMarker(key: $key, point: $point, width: $width, height: $height)';
  }
}

void _debugAssertNoDuplicateOptionTypes(List<MarkerOptions> options) {
  assert(() {
    final seen = <Type>{};
    for (final o in options) {
      final t = o.runtimeType;
      if (!seen.add(t)) {
        throw FlutterError('Duplicate MarkerOptions type detected: $t');
      }
    }
    return true;
  }());
}

extension MarkerOptionsListX on List<MarkerOptions> {
  T? opt<T extends MarkerOptions>() {
    for (final o in this) {
      if (o is T) return o;
    }
    return null;
  }

  List<MarkerOptions> setOpt<T extends MarkerOptions>(T value) {
    final out = List<MarkerOptions>.of(this);
    final i = out.indexWhere((o) => o is T);
    if (i >= 0) {
      out[i] = value;
    } else {
      out.add(value);
    }
    return out;
  }

  List<MarkerOptions> removeOpt<T extends MarkerOptions>() {
    final out = List<MarkerOptions>.of(this)..removeWhere((o) => o is T);
    return out;
  }
}
