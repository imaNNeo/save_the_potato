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

class UnknownError extends DomainError {}
