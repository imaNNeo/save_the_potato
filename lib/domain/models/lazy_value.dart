import 'dart:async';

/// This class is used for when we don't know when the value will be set,
/// but we want to use it as soon as possible.
/// You can await on the [value] getter to get the value.
/// If value already exists, it returns it immediately, otherwise it waits until
/// [setValue] is called
class LazyValue<T> {
  /// The value of the lazy value
  T? _value;

  /// This is used to complete the future returned by [value] when [setValue]
  /// is called for the first time
  final _valueInitialCompleter = Completer<T>();

  /// Returns either the [_value] if it exists, or a future that will
  /// complete when [setValue] is called
  Future<T> get value => _value != null
      ? Future.value(_value)
      : _valueInitialCompleter.future;

  /// Sets the value and completes the future returned by [value]
  /// if it is the first time
  void setValue(T value) {
    if (!_valueInitialCompleter.isCompleted) {
      _valueInitialCompleter.complete(value);
    }
    _value = value;
  }
}