import 'package:flutter/widgets.dart';
import 'package:flutter_map_interactive/common/interactive_scope.dart';
import 'package:flutter_map_interactive/common/options.dart';

/// Shared utility methods for scope widgets to reduce code duplication.
///
/// Each scope widget can use these helpers to look up options from the
/// nearest [InheritedInteractiveScope] ancestor.
class ScopeHelpers {
  ScopeHelpers._();

  /// Looks up the [InteractiveOptions] from the nearest ancestor scope.
  ///
  /// Returns `null` if no ancestor scope is found.
  static InteractiveOptions<T>? maybeOptionsOf<T extends Object>(
    BuildContext context,
  ) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InheritedInteractiveScope<T>>();
    return scope?.options;
  }

  /// Looks up the [InteractiveOptions] from the nearest ancestor scope.
  ///
  /// Throws [FlutterError] if no ancestor scope is found.
  static InteractiveOptions<T> optionsOf<T extends Object>(
    BuildContext context,
    String scopeName,
  ) {
    final options = maybeOptionsOf<T>(context);
    if (options == null) {
      throw FlutterError(
        'InteractiveOptions.of() called without an `$scopeName` ancestor.',
      );
    }
    return options;
  }
}
