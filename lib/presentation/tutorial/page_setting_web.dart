import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// A string the host page sets on `window`, e.g. the preview page's
/// tutorial picker
String? pageSetting(String name) {
  final value = globalContext.getProperty<JSAny?>(name.toJS);
  return value.isA<JSString>() ? (value as JSString).toDart : null;
}
