import 'package:flutter/widgets.dart';

/// Abstract State class for interactive layers that use a controller.
///
/// Handles initialization, updates, and disposal of the controller.
/// [T] is the StatefulWidget type.
/// [C] is the Controller type (must be disposable).
abstract class InteractiveLayerState<T extends StatefulWidget,
    C extends ChangeNotifier> extends State<T> {
  late C controller;

  /// Override to return the controller passed in widget parameters (may be null).
  C? get widgetController;

  /// Override to create a default controller if none is provided.
  C createDefaultController();

  /// Called when the controller is initialized (first time or reset).
  /// Use this to set options, initial data, etc.
  void onInitController(C controller);

  /// Called when the widget updates.
  /// Use this to update options on the existing controller.
  void onUpdateController(C controller);

  @override
  void initState() {
    super.initState();
    initControllers();
  }

  @mustCallSuper
  void initControllers() {
    controller = widgetController ?? createDefaultController();
    onInitController(controller);
  }

  @mustCallSuper
  void disposeControllersIfNeeded() {
    if (widgetController == null) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    disposeControllersIfNeeded();
    super.dispose();
  }
}
