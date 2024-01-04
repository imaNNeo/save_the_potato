extension StringExtensions on String {
  bool get asBool => toLowerCase() == 'true';

  double get asDouble => double.parse(this);

  int get asInt => int.parse(this);

  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => isBlank;
}

extension NullableStringExtension on String? {
  bool get isNullOrBlank => this == null || this!.isBlank;

  bool get isNotNullOrBlank => !isNullOrBlank;
}
