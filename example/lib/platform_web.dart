import 'dart:js_interop';
import 'package:web/web.dart';

void platformInit() {
  window.document.addEventListener(
      'contextmenu',
      (MouseEvent event) {
        event.preventDefault();
      }.toJS);
}
