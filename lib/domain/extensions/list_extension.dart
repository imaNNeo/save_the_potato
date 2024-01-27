extension ListExtension<T> on List<T> {
  List<T> randomOrder() {
    final List<T> copy = List<T>.from(this);
    copy.shuffle();
    return copy;
  }

  List<T> updateAndReturn(int index, T newItem) {
    final List<T> copy = List<T>.from(this);
    copy[index] = newItem;
    return copy;
  }
}