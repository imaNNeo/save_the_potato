import 'dart:js_interop';

@JS('potatoFace')
external JSString? get _potatoFace;

/// PROTOTYPE: the recovery face picked on the preview page
/// (`window.potatoFace`), or `?face=` in the URL.
String? pickedRecoveryFace() =>
    _potatoFace?.toDart ?? Uri.base.queryParameters['face'];
