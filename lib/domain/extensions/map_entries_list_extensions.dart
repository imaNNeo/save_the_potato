extension MapEntriesListExtension<K, V> on List<MapEntry<K, V>> {
  Map<K, V> toMap() => Map.fromEntries(this);
}

extension MapEntriesIterableExtension<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() => Map.fromEntries(this);
}
