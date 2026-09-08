import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/markers/layers/options.dart';
import 'package:flutter_map_interactive/markers/models/interactive_marker.dart';
import 'package:flutter_map_interactive/utils/matrix.dart';
import 'package:latlong2/latlong.dart';

extension IterableMarkerX on List<Marker> {
  int indexOfKey(Key? key) {
    if (key == null) {
      throw ArgumentError('Key cannot be null');
    }
    final idx = indexWhere((m) => m.key == key);
    if (idx < 0) {
      throw StateError('Marker not found for key : $key');
    }
    return idx;
  }

  int tryIndexOfKey(Key? key) =>
      key == null ? -1 : indexWhere((m) => m.key == key);

  ({bool removed, int index, Marker? marker}) removeAtKey(Key? key) {
    final idx = tryIndexOfKey(key);
    if (idx < 0) return (removed: false, index: idx, marker: null);
    return (removed: true, index: idx, marker: removeAt(idx));
  }

  Marker findByKey(Key? key) {
    final idx = indexOfKey(key);
    return this[idx];
  }

  Marker? findByKeyOrNull(Key? key) => firstWhereOrNull((m) => m.key == key);

  Marker updateByKey(Key? key, Marker newMarker) {
    final idx = indexOfKey(key);
    this[idx] = newMarker;
    return this[idx];
  }

  Marker updatePointByKey(Key? key, LatLng latlng) {
    final idx = indexOfKey(key);
    final oldMarker = this[idx];
    this[idx] = oldMarker.copyWith(point: latlng);
    return this[idx];
  }
}

extension MarkerX on Marker {
  Marker copyWith({
    LatLng? point,
    Widget? child,
    double? width,
    double? height,
    Alignment? alignment,
    bool? rotate,
  }) {
    final marker = this;
    if (marker is InteractiveMarker) {
      return marker.copyWith(
        point: point,
        child: child,
        width: width,
        height: height,
        alignment: alignment,
        rotate: rotate,
      );
    }
    return Marker(
      key: key,
      point: point ?? this.point,
      child: child ?? this.child,
      width: width ?? this.width,
      height: height ?? this.height,
      alignment: alignment ?? this.alignment,
      rotate: rotate ?? this.rotate,
    );
  }

  void ensureHasKey() {
    if (key == null) {
      throw ArgumentError('Marker must have a non-null key.');
    }
  }

  bool inMapBounds(MapCamera cam, {MarkerLayerOptions? options, bool? active}) {
    final bounds = pixelBounds(cam, options: options, active: active);
    final view = Offset.zero & cam.nonRotatedSize;
    return view.overlaps(bounds);
  }

  bool inPixelsBounds(MapCamera cam, Offset offset,
      {MarkerLayerOptions? options, bool? active}) {
    final bounds = pixelBounds(cam, options: options, active: active);
    return bounds.contains(offset);
  }

  Rect pixelBounds(MapCamera cam, {MarkerLayerOptions? options, bool? active}) {
    final px = cam.latLngToScreenOffset(point);
    final align = alignment ?? options?.alignment ?? Alignment.center;
    final size =
        resolveSize(options: options, active: active ?? false, touch: true);
    final rot = rotate ?? options?.rotate ?? false;

    return overlayRect(
      origin: px,
      size: size,
      alignment: align,
      mapRotationRad: cam.rotationRad,
      rotate: rot,
    );
  }

  double resolveScale(
          {MarkerLayerOptions? options,
          bool active = false,
          bool touch = false}) =>
      resolveMarkerScale(this, options: options, active: active, touch: touch);

  Size resolveSize(
      {MarkerLayerOptions? options, bool active = false, bool touch = false}) {
    final s = resolveScale(options: options, active: active, touch: touch);
    return Size(width * s, height * s);
  }
}

double resolveMarkerScale(Marker m,
    {MarkerLayerOptions? options, bool active = false, bool touch = false}) {
  final selM =
      (m is InteractiveMarker) ? m.activeOptions?.activeSizeFactor : null;
  final selL =
      (options is InteractiveLayerOptions) ? options.activeSizeFactor : null;
  final touchM =
      (m is InteractiveMarker) ? m.activeOptions?.touchSizeFactor : null;
  final touchL =
      (options is InteractiveLayerOptions) ? options.touchSizeFactor : null;

  final activeScale = selM ?? selL ?? 1.0;
  final touchScale = touchM ?? touchL ?? 1.0;

  return active
      ? (touch ? touchScale * activeScale : activeScale)
      : (touch ? touchScale : 1.0);
}

extension MapControllerX on MapController {
  void centerPointAnimated(TickerProvider vsync, LatLng point,
      {Duration duration = const Duration(milliseconds: 250), double? zoom}) {
    final tween = LatLngTween(begin: camera.center, end: point);
    final ctrl = AnimationController(vsync: vsync, duration: duration);
    final anim = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);

    ctrl.addListener(() => move(tween.evaluate(anim), zoom ?? camera.zoom));
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) ctrl.dispose();
    });
    ctrl.forward();
  }

  void centerMarkerAnimated(TickerProvider vsync, Marker marker,
          {Duration duration = const Duration(milliseconds: 250)}) =>
      centerPointAnimated(vsync, marker.point, duration: duration);

  void centerOffsetAnimated(TickerProvider vsync, Offset offset,
      {Duration duration = const Duration(milliseconds: 250)}) {
    final latLng = camera.screenOffsetToLatLng(offset);
    centerPointAnimated(vsync, latLng, duration: duration);
  }

  void panByOffset(Offset offset) {
    final latLng = camera.newCenterFromOffset(offset);
    move(latLng, camera.zoom);
  }

  void panByOffsetAnimated(
      TickerProvider vsync, Offset offset, Duration duration) {
    final latLng = camera.newCenterFromOffset(offset);
    centerPointAnimated(vsync, latLng, duration: duration);
  }
}

extension MapCameraX on MapCamera {
  LatLng screenOffsetToLatLngUnrotated(Offset offset) {
    final localPointCenterDistance =
        nonRotatedSize.center(Offset.zero) - offset;
    final mapCenter = crs.latLngToOffset(center, zoom);

    final point = mapCenter - localPointCenterDistance;

    return crs.offsetToLatLng(point, zoom);
  }

  Offset latLngToScreenOffsetUnrotated(LatLng latLng) {
    final nonRotatedPixelOrigin =
        projectAtZoom(center, zoom) - nonRotatedSize.center(Offset.zero);

    final point = crs.latLngToOffset(latLng, zoom);

    return point - nonRotatedPixelOrigin;
  }

  Offset latLngToLayerOffset(LatLng latlng) {
    final world = crs.latLngToOffset(latlng, zoom);
    return world - pixelOrigin;
  }

  LatLng newCenterFromOffset(Offset offset) {
    final mapCenter = latLngToScreenOffset(center);
    final newCenter = screenOffsetToLatLng(mapCenter - offset);
    return newCenter;
  }
}
