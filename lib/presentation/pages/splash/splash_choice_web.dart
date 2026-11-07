import 'dart:js_interop';

@JS('potatoSplash')
external JSString? get _potatoSplash;

/// The splash concept the preview page picked (`window.potatoSplash`)
String? pickedSplashConcept() => _potatoSplash?.toDart;
