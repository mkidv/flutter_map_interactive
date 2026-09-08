import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show Polyline, StrokePattern;
import 'package:flutter_map_interactive/polylines/models/options.dart';
import 'package:latlong2/latlong.dart';

/// A wrapper around [Polyline] that adds identification and data.
class InteractivePolyline<R extends Object> extends Polyline<R> {
  InteractivePolyline({
    required super.points,
    this.key,
    super.strokeWidth = 4.0,
    super.pattern = const StrokePattern.solid(),
    super.color = const Color(0xFF00FF00),
    super.borderStrokeWidth = 0.0,
    super.borderColor = const Color(0xFFFFFF00),
    super.gradientColors,
    super.colorsStop,
    super.strokeCap = StrokeCap.round,
    super.strokeJoin = StrokeJoin.round,
    super.useStrokeWidthInMeter = false,
    super.hitValue,
    this.options = const [],
  });

  factory InteractivePolyline.safe({
    required List<LatLng> points,
    Key? key,
    double strokeWidth = 4.0,
    Color color = const Color(0xFF00FF00),
    double borderStrokeWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
    List<Color>? gradientColors,
    List<double>? colorsStop,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
    bool useStrokeWidthInMeter = false,
    R? hitValue,
    List<PolylineOptions> options = const [],
  }) {
    _debugAssertNoDuplicateOptionTypes(options);
    return InteractivePolyline(
      key: key,
      points: points,
      strokeWidth: strokeWidth,
      color: color,
      borderStrokeWidth: borderStrokeWidth,
      borderColor: borderColor,
      gradientColors: gradientColors,
      colorsStop: colorsStop,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      useStrokeWidthInMeter: useStrokeWidthInMeter,
      hitValue: hitValue,
      options: List<PolylineOptions>.unmodifiable(options),
    );
  }
  final Key? key;
  final List<PolylineOptions> options;

  static InteractivePolyline fromPolyline(Polyline polyline) {
    return polyline is InteractivePolyline
        ? polyline
        : InteractivePolyline(
            key: UniqueKey(),
            points: polyline.points,
            pattern: polyline.pattern,
            strokeWidth: polyline.strokeWidth,
            color: polyline.color,
            borderStrokeWidth: polyline.borderStrokeWidth,
            borderColor: polyline.borderColor,
            gradientColors: polyline.gradientColors,
            colorsStop: polyline.colorsStop,
            strokeCap: polyline.strokeCap,
            strokeJoin: polyline.strokeJoin,
            useStrokeWidthInMeter: polyline.useStrokeWidthInMeter,
            hitValue: polyline.hitValue,
          );
  }

  LabelPolylineOptions? get labelOptions => options.opt<LabelPolylineOptions>();
  ActionPolylineOptions? get actionOptions =>
      options.opt<ActionPolylineOptions>();
  GesturePolylineOptions? get gestureOptions =>
      options.opt<GesturePolylineOptions>();
  ActivePolylineOptions? get activeOptions =>
      options.opt<ActivePolylineOptions>();
  PopupPolylineOptions? get popupOptions => options.opt<PopupPolylineOptions>();

  InteractivePolyline copyWith({
    List<LatLng>? points,
    StrokePattern? pattern,
    double? strokeWidth,
    Color? color,
    double? borderStrokeWidth,
    Color? borderColor,
    List<Color>? gradientColors,
    List<double>? colorsStop,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    bool? useStrokeWidthInMeter,
    R? hitValue,
    List<PolylineOptions>? options,
  }) {
    return InteractivePolyline(
      key: key,
      points: points ?? this.points,
      pattern: pattern ?? this.pattern,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      color: color ?? this.color,
      borderStrokeWidth: borderStrokeWidth ?? this.borderStrokeWidth,
      borderColor: borderColor ?? this.borderColor,
      gradientColors: gradientColors ?? this.gradientColors,
      colorsStop: colorsStop ?? this.colorsStop,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      useStrokeWidthInMeter:
          useStrokeWidthInMeter ?? this.useStrokeWidthInMeter,
      hitValue: hitValue ?? this.hitValue,
      options: List<PolylineOptions>.of(options ?? this.options),
    );
  }

  InteractivePolyline withOption<T extends PolylineOptions>(T opt) =>
      copyWith(options: options.setOpt<T>(opt));

  InteractivePolyline withoutOption<T extends PolylineOptions>() =>
      copyWith(options: options.removeOpt<T>());

  void ensureHasKey() {
    if (key == null) {
      throw ArgumentError('Polyline must have a non-null key.');
    }
  }

  @override
  bool operator ==(Object other) {
    return other is InteractivePolyline &&
        runtimeType == other.runtimeType &&
        key == other.key &&
        points == other.points;
  }

  @override
  int get hashCode => Object.hash(runtimeType, key, points);

  @override
  String toString() {
    return 'InteractivePolyline(key: $key, points: $points, hitValue: $hitValue)';
  }
}

void _debugAssertNoDuplicateOptionTypes(List<PolylineOptions> options) {
  assert(() {
    final seen = <Type>{};
    for (final o in options) {
      final t = o.runtimeType;
      if (!seen.add(t)) {
        throw FlutterError('Duplicate PolylineOptions type detected: $t');
      }
    }
    return true;
  }());
}

extension PolylineOptionsListX on List<PolylineOptions> {
  T? opt<T extends PolylineOptions>() {
    for (final o in this) {
      if (o is T) return o;
    }
    return null;
  }

  List<PolylineOptions> setOpt<T extends PolylineOptions>(T value) {
    final out = List<PolylineOptions>.of(this);
    final i = out.indexWhere((o) => o is T);
    if (i >= 0) {
      out[i] = value;
    } else {
      out.add(value);
    }
    return out;
  }

  List<PolylineOptions> removeOpt<T extends PolylineOptions>() {
    final out = List<PolylineOptions>.of(this)..removeWhere((o) => o is T);
    return out;
  }
}

extension IterablePolylineX on List<InteractivePolyline> {
  int indexOfKey(Key? key) {
    if (key == null) {
      throw ArgumentError('Key cannot be null');
    }
    final idx = indexWhere((p) => p.key == key);
    if (idx < 0) {
      throw StateError('Polyline not found for key : $key');
    }
    return idx;
  }

  int tryIndexOfKey(Key? key) =>
      key == null ? -1 : indexWhere((p) => p.key == key);

  ({bool removed, int index, InteractivePolyline? polyline}) removeAtKey(
      Key? key) {
    final idx = tryIndexOfKey(key);
    if (idx < 0) return (removed: false, index: idx, polyline: null);
    return (removed: true, index: idx, polyline: removeAt(idx));
  }

  InteractivePolyline findByKey(Key? key) {
    final idx = indexOfKey(key);
    return this[idx];
  }

  InteractivePolyline? findByKeyOrNull(Key? key) {
    if (key == null) return null;
    for (final p in this) {
      if (p.key == key) return p;
    }
    return null;
  }

  InteractivePolyline updateByKey(Key? key, InteractivePolyline newPolyline) {
    final idx = indexOfKey(key);
    this[idx] = newPolyline;
    return this[idx];
  }
}
