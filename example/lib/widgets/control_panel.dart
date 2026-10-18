import 'package:flutter/material.dart';
import 'package:flutter_map_interactive/flutter_map_interactive.dart';

/// Uses the same controller API for all three demo scenes.
class DemoControls extends StatelessWidget {
  const DemoControls({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onReset,
    required this.onCenter,
    required this.onSaved,
  });

  final InteractiveController<Object> controller;
  final VoidCallback onAdd;
  final VoidCallback onReset;
  final VoidCallback onCenter;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Edit mode'),
              subtitle: Text('${controller.current.length} items · '
                  '${controller.hasUnsavedChanges ? 'Unsaved changes' : 'At checkpoint'}'),
              value: controller.isEditing,
              onChanged: controller.setEditMode,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add at center')),
                OutlinedButton.icon(
                  onPressed: controller.hasActive
                      ? () => controller.remove(controller.activeKey!)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete selected'),
                ),
                OutlinedButton(
                    onPressed: controller.canUndo ? controller.undo : null,
                    child: const Text('Undo')),
                OutlinedButton(
                    onPressed: controller.canRedo ? controller.redo : null,
                    child: const Text('Redo')),
                OutlinedButton(
                  onPressed: controller.hasUnsavedChanges
                      ? () {
                          controller.save();
                          onSaved();
                        }
                      : null,
                  child: const Text('Save checkpoint'),
                ),
                OutlinedButton(
                    onPressed: controller.hasUnsavedChanges
                        ? controller.discard
                        : null,
                    child: const Text('Discard changes')),
                TextButton.icon(
                    onPressed: onCenter,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Recenter')),
                TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset scene')),
              ],
            ),
          ],
        ),
      );
}
