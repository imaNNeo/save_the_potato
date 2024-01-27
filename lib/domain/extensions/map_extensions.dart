extension DynamicMapExtension on Map<dynamic, dynamic> {
  Map<String, dynamic> asStringMap() =>
      map((key, value) => MapEntry(key as String, value as dynamic));
}

extension NullableMapExtension on Map<String, dynamic> {
  Map<String, dynamic> removeNullValues() =>
      Map.fromEntries(entries.where((element) => element.value != null));
}
