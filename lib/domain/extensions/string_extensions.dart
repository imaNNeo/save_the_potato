extension StringExtensions on String {
  bool get asBool => toLowerCase() == 'true';
  double get asDouble => double.parse(this);
  int get asInt => int.parse(this);
}