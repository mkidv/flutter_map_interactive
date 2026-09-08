import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';

enum LayerType { marker, polyline, overlay }

class Toolbox extends StatefulWidget {
  final MarkerController markerController;
  final PolylineController polylineController;
  final OverlayController overlayController;

  final VoidCallback onAddMarker;
  final VoidCallback onAddPolyline;
  final VoidCallback onAddOverlay;

  final VoidCallback onClearMarkers;
  final VoidCallback onClearPolylines;
  final VoidCallback onClearOverlays;

  const Toolbox({
    super.key,
    required this.markerController,
    required this.polylineController,
    required this.overlayController,
    required this.onAddMarker,
    required this.onAddPolyline,
    required this.onAddOverlay,
    required this.onClearMarkers,
    required this.onClearPolylines,
    required this.onClearOverlays,
  });

  @override
  State<Toolbox> createState() => _ToolboxState();
}

class _ToolboxState extends State<Toolbox> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  dynamic get _currentController {
    switch (_tabController.index) {
      case 0:
        return widget.markerController;
      case 1:
        return widget.polylineController;
      case 2:
        return widget.overlayController;
      default:
        return widget.markerController;
    }
  }

  VoidCallback get _currentAdd {
    switch (_tabController.index) {
      case 0:
        return widget.onAddMarker;
      case 1:
        return widget.onAddPolyline;
      case 2:
        return widget.onAddOverlay;
      default:
        return widget.onAddMarker;
    }
  }

  VoidCallback get _currentClear {
    switch (_tabController.index) {
      case 0:
        return widget.onClearMarkers;
      case 1:
        return widget.onClearPolylines;
      case 2:
        return widget.onClearOverlays;
      default:
        return widget.onClearMarkers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 140, // Fixed width for stability
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: false, // Fits in small width
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              onTap: (i) => setState(() {}),
              tabs: const [
                Tab(
                    icon: Icon(Icons.location_on_outlined, size: 20),
                    height: 36),
                Tab(icon: Icon(Icons.polyline_outlined, size: 20), height: 36),
                Tab(icon: Icon(Icons.image_outlined, size: 20), height: 36),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions for current tab
            _ToolboxButton(
              icon: Icons.add,
              label: 'Add New',
              onPressed: _currentAdd,
              tooltip: 'Add Item',
            ),
            const SizedBox(height: 8),
            _ToolboxButton(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear',
              onPressed: _currentClear,
              tooltip: 'Clear Items',
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Controller Actions (Dynamic based on tab)
            // We need to pass the specific controller type to buttons, but they expect dynamic/specific
            // logic inside common buttons might need casting or specific method calls if not covariant.
            // Fortunately EditMode... buttons take dynamic or specific?
            // Checking ui.dart: EditModeToggleButton takes `dynamic controller`.

            EditModeToggleButton(controller: _currentController),
            const SizedBox(height: 8),
            EditModeUndoButton(controller: _currentController),
            const SizedBox(height: 8),
            EditModeRedoButton(controller: _currentController),
            const SizedBox(height: 8),
            IconButton(
              onPressed: () => (_currentController as dynamic).save(),
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save Changes',
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolboxButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const _ToolboxButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color ?? theme.colorScheme.onSurface, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
