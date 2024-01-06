import 'package:equatable/equatable.dart';

sealed class DomainError implements Exception {}

class NetworkError extends DomainError {}

class ServerError extends DomainError {
  final ServerErrorEntry? errorEntry;

  ServerError({
    this.errorEntry,
  });
}

class ServerErrorEntry {
  final String? message;
  final String? details;

  ServerErrorEntry(
    this.message,
    this.details,
  );

  String? get detailsOrMessage => details ?? message;
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
