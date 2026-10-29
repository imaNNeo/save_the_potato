import 'package:equatable/equatable.dart';

sealed class DomainError implements Exception {}

class NetworkError extends DomainError {}

class ServerError extends DomainError with Equatable {
  final ServerErrorEntry? errorEntry;

  ServerError({this.errorEntry});

  @override
  String toString() => '$runtimeType(${props.join(', ')})';

  @override
  List<Object?> get props => [errorEntry];
}

class ServerErrorEntry with Equatable {
  final String? message;
  final String? details;

  ServerErrorEntry(this.message, this.details);

  String? get detailsOrMessage => details ?? message;

  @override
  String toString() => '$runtimeType(${props.join(', ')})';

  @override
  List<Object?> get props => [message, details];
}

class AccountAlreadyExistsError extends DomainError with Equatable {
  final String? email;

  AccountAlreadyExistsError({required this.email});

  @override
  List<Object?> get props => [email];
}

class UnknownError extends DomainError {}
