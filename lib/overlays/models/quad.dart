import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum QuadCorner { topLeft, topRight, bottomRight, bottomLeft }

class QuadLatLng {
  const QuadLatLng({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final LatLng topLeft;
  final LatLng topRight;
  final LatLng bottomRight;
  final LatLng bottomLeft;

  LatLng pointAt(QuadCorner corner) {
    switch (corner) {
      case QuadCorner.topLeft:
        return topLeft;
      case QuadCorner.topRight:
        return topRight;
      case QuadCorner.bottomRight:
        return bottomRight;
      case QuadCorner.bottomLeft:
        return bottomLeft;
    }
  }

  QuadLatLng copyWith({
    LatLng? topLeft,
    LatLng? topRight,
    LatLng? bottomRight,
    LatLng? bottomLeft,
  }) {
    return QuadLatLng(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomRight: bottomRight ?? this.bottomRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
    );
  }

  QuadLatLng copyWithCorner(QuadCorner corner, LatLng point) {
    return switch (corner) {
      QuadCorner.topLeft => copyWith(topLeft: point),
      QuadCorner.topRight => copyWith(topRight: point),
      QuadCorner.bottomRight => copyWith(bottomRight: point),
      QuadCorner.bottomLeft => copyWith(bottomLeft: point),
    };
  }

  LatLng get center {
    final lat = (topLeft.latitude +
            topRight.latitude +
            bottomRight.latitude +
            bottomLeft.latitude) /
        4.0;
    final lng = (topLeft.longitude +
            topRight.longitude +
            bottomRight.longitude +
            bottomLeft.longitude) /
        4.0;
    return LatLng(lat, lng);
  }

  LatLngBounds get bounds {
    // Simple bounds that encompass the Quad
    return LatLngBounds.fromPoints(
        [topLeft, topRight, bottomRight, bottomLeft]);
  }

  List<LatLng> get asList => [topLeft, topRight, bottomRight, bottomLeft];

  QuadLatLng translate(double deltaLat, double deltaLng) {
    return QuadLatLng(
      topLeft:
          LatLng(topLeft.latitude + deltaLat, topLeft.longitude + deltaLng),
      topRight:
          LatLng(topRight.latitude + deltaLat, topRight.longitude + deltaLng),
      bottomRight: LatLng(
          bottomRight.latitude + deltaLat, bottomRight.longitude + deltaLng),
      bottomLeft: LatLng(
          bottomLeft.latitude + deltaLat, bottomLeft.longitude + deltaLng),
    );
  }

  QuadLatLng rotate(double angleRad, {LatLng? anchor}) {
    final centerPoint = anchor ?? center;
    const distance = Distance();

    // Helper to rotate a single point
    LatLng rotatePoint(LatLng point) {
      final dist = distance.as(LengthUnit.Meter, centerPoint, point);
      final bear = distance.bearing(centerPoint, point);

      // Convert radians to degrees for the Distance library
      final angleDeg = angleRad * 180.0 / math.pi;
      final newBear = bear + angleDeg;

      return distance.offset(centerPoint, dist, newBear);
    }

    return QuadLatLng(
      topLeft: rotatePoint(topLeft),
      topRight: rotatePoint(topRight),
      bottomRight: rotatePoint(bottomRight),
      bottomLeft: rotatePoint(bottomLeft),
    );
  }

  /// Checks if [point] is inside this quad (assuming convex plain polygon projection).
  bool contains(LatLng point) {
    bool isLeft(LatLng p1, LatLng p2, LatLng p) {
      return ((p2.longitude - p1.longitude) * (p.latitude - p1.latitude) -
              (p2.latitude - p1.latitude) * (p.longitude - p1.longitude)) >
          0;
    }

    // Check winding order (standard is usually counter-clockwise or clockwise)
    // Here we check if point is on the same side of all segments.
    // TL -> TR -> BR -> BL -> TL
    final b1 = isLeft(topLeft, topRight, point);
    final b2 = isLeft(topRight, bottomRight, point);
    final b3 = isLeft(bottomRight, bottomLeft, point);
    final b4 = isLeft(bottomLeft, topLeft, point);

    // If strictly convex, all should be same boolean (all True or all False)
    return (b1 == b2) && (b2 == b3) && (b3 == b4);
  }

  // Midpoints
  LatLng get topMid => LatLng((topLeft.latitude + topRight.latitude) / 2,
      (topLeft.longitude + topRight.longitude) / 2);
  LatLng get rightMid => LatLng((topRight.latitude + bottomRight.latitude) / 2,
      (topRight.longitude + bottomRight.longitude) / 2);
  LatLng get bottomMid => LatLng(
      (bottomRight.latitude + bottomLeft.latitude) / 2,
      (bottomRight.longitude + bottomLeft.longitude) / 2);
  LatLng get leftMid => LatLng((bottomLeft.latitude + topLeft.latitude) / 2,
      (bottomLeft.longitude + topLeft.longitude) / 2);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuadLatLng &&
          runtimeType == other.runtimeType &&
          topLeft == other.topLeft &&
          topRight == other.topRight &&
          bottomRight == other.bottomRight &&
          bottomLeft == other.bottomLeft;

  @override
  int get hashCode =>
      topLeft.hashCode ^
      topRight.hashCode ^
      bottomRight.hashCode ^
      bottomLeft.hashCode;

  @override
  String toString() =>
      'QuadLatLng(tl: $topLeft, tr: $topRight, br: $bottomRight, bl: $bottomLeft)';
}
