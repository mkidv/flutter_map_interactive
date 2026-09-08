import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/entity_delta.dart';

/// Options for auto-panning the map when dragging near edges.
class AutoPanOnDragOptions {
  const AutoPanOnDragOptions({
    this.enabled = true,
    this.safePadding = const EdgeInsets.all(16),
    this.minStepPx = 6.0,
    this.maxStepPx = 36.0,
    this.gain = 0.25,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  /// Whether auto-pan is enabled.
  final bool enabled;

  /// Safe padding from edges before auto-pan activates.
  final EdgeInsets safePadding;

  /// Minimum pan step in pixels.
  final double minStepPx;

  /// Maximum pan step in pixels.
  final double maxStepPx;

  /// Pan speed gain factor.
  final double gain;

  /// Whether to animate pan movements.
  final bool animated;

  /// Duration of pan animation.
  final Duration animationDuration;

  AutoPanOnDragOptions copyWith({
    bool? enabled,
    EdgeInsets? safePadding,
    double? minStepPx,
    double? maxStepPx,
    double? gain,
    bool? animated,
    Duration? animationDuration,
  }) {
    return AutoPanOnDragOptions(
      enabled: enabled ?? this.enabled,
      safePadding: safePadding ?? this.safePadding,
      minStepPx: minStepPx ?? this.minStepPx,
      maxStepPx: maxStepPx ?? this.maxStepPx,
      gain: gain ?? this.gain,
      animated: animated ?? this.animated,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoPanOnDragOptions &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          safePadding == other.safePadding &&
          minStepPx == other.minStepPx &&
          maxStepPx == other.maxStepPx &&
          gain == other.gain &&
          animated == other.animated &&
          animationDuration == other.animationDuration;

  @override
  int get hashCode => Object.hash(
        enabled,
        safePadding,
        minStepPx,
        maxStepPx,
        gain,
        animated,
        animationDuration,
      );
}

/// Configuration for which gestures are enabled.
class InteractiveEnabledGestures {
  const InteractiveEnabledGestures({
    this.tap = true,
    this.longPress = true,
    this.drag = true,
    this.hover = true,
  });

  /// All gestures disabled.
  factory InteractiveEnabledGestures.none() => const InteractiveEnabledGestures(
        tap: false,
        longPress: false,
        drag: false,
        hover: false,
      );

  /// All gestures enabled.
  factory InteractiveEnabledGestures.all() =>
      const InteractiveEnabledGestures();

  /// Whether tap gesture is enabled.
  final bool tap;

  /// Whether long-press gesture is enabled.
  final bool longPress;

  /// Whether drag gesture is enabled.
  final bool drag;

  /// Whether hover gesture is enabled.
  final bool hover;

  InteractiveEnabledGestures copyWith({
    bool? tap,
    bool? longPress,
    bool? drag,
    bool? hover,
  }) {
    return InteractiveEnabledGestures(
      tap: tap ?? this.tap,
      longPress: longPress ?? this.longPress,
      drag: drag ?? this.drag,
      hover: hover ?? this.hover,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveEnabledGestures &&
          runtimeType == other.runtimeType &&
          tap == other.tap &&
          longPress == other.longPress &&
          drag == other.drag &&
          hover == other.hover;

  @override
  int get hashCode => Object.hash(tap, longPress, drag, hover);
}

typedef InteractiveCallback<T> = void Function(T entity);

/// Main configuration options for interactive layers.
class InteractiveOptions<T> {
  const InteractiveOptions({
    this.enabledGestures = const InteractiveEnabledGestures(),
    this.autoPanOnDrag = const AutoPanOnDragOptions(),
    this.moveOnTap = false,
    this.centerOnTap = true,
    this.onActive,
    this.onTap,
    this.onLongPress,
    this.onHovered,
    this.saveOnExit = true,
    this.autoSave = false,
    this.autoSaveDelay = const Duration(milliseconds: 700),
    this.mergeDelay = const Duration(milliseconds: 150),
    this.onSaved,
    this.onAdded,
    this.onRemoved,
    this.onUpdated,
    this.onSpatialUpdate,
    this.onEditModeChanged,
  });

  /// Which gestures are enabled.
  final InteractiveEnabledGestures enabledGestures;

  /// Auto-pan options when dragging near edges.
  final AutoPanOnDragOptions autoPanOnDrag;

  /// Whether to move to tapped location.
  final bool moveOnTap;

  /// Whether to center on tap.
  final bool centerOnTap;

  // Interaction Callbacks
  /// Called when an item becomes active.
  final InteractiveCallback<T>? onActive;

  /// Called when an item is tapped.
  final InteractiveCallback<T>? onTap;

  /// Called when an item is long-pressed.
  final InteractiveCallback<T>? onLongPress;

  /// Called when an item is hovered.
  final InteractiveCallback<T>? onHovered;

  // Edition Options
  /// Whether to save changes when exiting edit mode.
  final bool saveOnExit;

  /// Whether to automatically save local changes while editing.
  final bool autoSave;

  /// Delay before auto-saving after a local change.
  final Duration autoSaveDelay;

  /// Delay for merging consecutive operations.
  final Duration mergeDelay;

  /// Called when changes are saved.
  final OnEntityDeltaCallback<T>? onSaved;

  /// Called when an item is added.
  final OnEntityChangedCallback<T>? onAdded;

  /// Called when an item is removed.
  final OnEntityChangedCallback<T>? onRemoved;

  /// Called when an item is updated.
  final OnEntityChangedCallback<T>? onUpdated;

  /// Called when an item's spatial position changes.
  final OnSpatialUpdateCallback<T>? onSpatialUpdate;

  /// Called when edit mode changes.
  final ValueChanged<bool>? onEditModeChanged;

  InteractiveOptions<T> copyWith({
    InteractiveEnabledGestures? enabledGestures,
    AutoPanOnDragOptions? autoPanOnDrag,
    bool? moveOnTap,
    bool? centerOnTap,
    InteractiveCallback<T>? onActive,
    InteractiveCallback<T>? onTap,
    InteractiveCallback<T>? onLongPress,
    InteractiveCallback<T>? onHovered,
    bool? saveOnExit,
    bool? autoSave,
    Duration? autoSaveDelay,
    Duration? mergeDelay,
    OnEntityDeltaCallback<T>? onSaved,
    OnEntityChangedCallback<T>? onAdded,
    OnEntityChangedCallback<T>? onRemoved,
    OnEntityChangedCallback<T>? onUpdated,
    OnSpatialUpdateCallback<T>? onSpatialUpdate,
    ValueChanged<bool>? onEditModeChanged,
  }) {
    return InteractiveOptions<T>(
      enabledGestures: enabledGestures ?? this.enabledGestures,
      autoPanOnDrag: autoPanOnDrag ?? this.autoPanOnDrag,
      moveOnTap: moveOnTap ?? this.moveOnTap,
      centerOnTap: centerOnTap ?? this.centerOnTap,
      onActive: onActive ?? this.onActive,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onHovered: onHovered ?? this.onHovered,
      saveOnExit: saveOnExit ?? this.saveOnExit,
      autoSave: autoSave ?? this.autoSave,
      autoSaveDelay: autoSaveDelay ?? this.autoSaveDelay,
      mergeDelay: mergeDelay ?? this.mergeDelay,
      onSaved: onSaved ?? this.onSaved,
      onAdded: onAdded ?? this.onAdded,
      onRemoved: onRemoved ?? this.onRemoved,
      onUpdated: onUpdated ?? this.onUpdated,
      onSpatialUpdate: onSpatialUpdate ?? this.onSpatialUpdate,
      onEditModeChanged: onEditModeChanged ?? this.onEditModeChanged,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveOptions<T> &&
          runtimeType == other.runtimeType &&
          enabledGestures == other.enabledGestures &&
          autoPanOnDrag == other.autoPanOnDrag &&
          moveOnTap == other.moveOnTap &&
          centerOnTap == other.centerOnTap &&
          saveOnExit == other.saveOnExit &&
          autoSave == other.autoSave &&
          autoSaveDelay == other.autoSaveDelay &&
          mergeDelay == other.mergeDelay;

  @override
  int get hashCode => Object.hash(
        enabledGestures,
        autoPanOnDrag,
        moveOnTap,
        centerOnTap,
        saveOnExit,
        autoSave,
        autoSaveDelay,
        mergeDelay,
      );
}

typedef OnEntityChangedCallback<T> = void Function(T entity);
typedef OnEntityDeltaCallback<T> = void Function(EntityDelta<T> delta);
typedef OnSpatialUpdateCallback<T> = void Function(T entity, T oldEntity);
