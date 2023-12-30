import 'package:equatable/equatable.dart';

/// A wrapper that can hold a null value
///
/// It can be used in the state.copyWith function when we want to pass
/// a null value for a field in the state class.
class ValueWrapper<T> with EquatableMixin {
  final T? value;

  T get nonNullValue => value!;

  bool get isNull => value == null;

  bool get isNotNull => !isNull;

  const ValueWrapper(this.value);

  factory ValueWrapper.nullValue() => const ValueWrapper(null);

  @override
  List<Object?> get props => [value];
}
