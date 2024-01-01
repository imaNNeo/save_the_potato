extension StringExtensions on String {
  bool get asBool => toLowerCase() == 'true';

  double get asDouble => double.parse(this);

  int get asInt => int.parse(this);

  bool get isBlank => trim().isEmpty;
}

extension NullableStringExtension on String? {
  bool get isNullOrBlank => this == null || this!.isBlank;

  bool get isNotNullOrBlank => !isNullOrBlank;
}
