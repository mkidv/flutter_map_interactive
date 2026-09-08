import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_interactive/common/interactive_controller.dart';
import 'package:flutter_map_interactive/reactive/selector.dart';
import 'package:flutter_map_interactive/utils/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const double _kInteractiveToolbarButtonSize = 40;
const double _kInteractiveToolbarIconSize = 22;

class MapControlButton extends StatelessWidget {
  const MapControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minWidth: _kInteractiveToolbarButtonSize, minHeight: _kInteractiveToolbarButtonSize),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: _kInteractiveToolbarIconSize),
          ),
        ),
      ),
    );
  }
}

class EditModeToggleButton extends StatelessWidget {
  const EditModeToggleButton({super.key, required this.controller});
  final InteractiveController<Object?> controller;

  @override
  Widget build(BuildContext context) {
    return ListenableSelector(
      listenable: controller,
      select: (i) => i.isEditing,
      builder: (context, isEditing) {
        return MapControlButton(
          tooltip: 'Toggle edit mode',
          icon: isEditing ? Icons.edit_off : Icons.edit,
          onPressed: controller.toggleEditMode,
        );
      },
    );
  }
}

class EditModeUndoButton extends StatelessWidget {
  const EditModeUndoButton({super.key, required this.controller});
  final InteractiveController<Object?> controller;

  @override
  Widget build(BuildContext context) {
    return ListenableSelector(
        listenable: controller,
        select: (e) => e.canUndo,
        builder: (context, canUndo) => MapControlButton(
            tooltip: 'Undo',
            onPressed: canUndo ? controller.undo : null,
            icon: Icons.undo,
          ));
  }
}

class EditModeRedoButton extends StatelessWidget {
  const EditModeRedoButton({super.key, required this.controller});
  final InteractiveController<Object?> controller;

  @override
  Widget build(BuildContext context) {
    return ListenableSelector(
        listenable: controller,
        select: (e) => e.canRedo,
        builder: (context, canRedo) => MapControlButton(
            tooltip: 'Redo',
            onPressed: canRedo ? controller.redo : null,
            icon: Icons.redo,
          ));
  }
}

class MapCenterButton extends StatelessWidget {
  const MapCenterButton({
    super.key,
    required this.map,
    required this.vsync,
    required this.center,
    required this.zoom,
    required this.tooltip,
  });
  
  final MapController map;
  final TickerProvider vsync;
  final LatLng center;
  final double zoom;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: MapControlButton(
        icon: Icons.my_location,
        tooltip: tooltip,
        onPressed: () => map.centerPointAnimated(vsync, center, zoom: zoom),
      ),
    );
  }
}

