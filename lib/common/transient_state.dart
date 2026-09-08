import 'package:latlong2/latlong.dart';

class TransientState<T> {
  const TransientState({
    required this.item,
    required this.origin,
    required this.current,
  });
  final T item;
  final LatLng origin;
  final LatLng current;

  TransientState<T> copyWith({
    T? item,
    LatLng? origin,
    LatLng? current,
  }) {
    return TransientState<T>(
      item: item ?? this.item,
      origin: origin ?? this.origin,
      current: current ?? this.current,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransientState<T> &&
        other.item == item &&
        other.origin == origin &&
        other.current == current;
  }

  @override
  int get hashCode => item.hashCode ^ origin.hashCode ^ current.hashCode;

  @override
  String toString() {
    return 'TransientState(item: $item, origin: $origin, current: $current)';
  }
}
