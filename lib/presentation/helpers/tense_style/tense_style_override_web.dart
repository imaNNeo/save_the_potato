import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The name of the tense style the page hosting the game asks for, set as
/// `window.potatoTenseStyle` before the game starts. Lets the web preview
/// compare the styles without a new build.
String? tenseStyleOverride() {
  final value = globalContext['potatoTenseStyle'];
  return value.isA<JSString>() ? (value as JSString).toDart : null;
}
