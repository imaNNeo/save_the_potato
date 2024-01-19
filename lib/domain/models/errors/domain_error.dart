import 'package:equatable/equatable.dart';

sealed class DomainError implements Exception {}

class NetworkError extends DomainError {}

class ServerError extends DomainError with EquatableMixin {
  final ServerErrorEntry? errorEntry;

  ServerError({
    this.errorEntry,
  });

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        errorEntry,
      ];
}

class ServerErrorEntry with EquatableMixin {
  final String? message;
  final String? details;

  ServerErrorEntry(
    this.message,
    this.details,
  );

  String? get detailsOrMessage => details ?? message;

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [
        message,
        details,
      ];
}

class AccountAlreadyExistsError extends DomainError with EquatableMixin {
  final String? email;

  AccountAlreadyExistsError({
    required this.email,
  });

  @override
  List<Object?> get props => [
        email,
      ];
}

class UnknownError extends DomainError {}
