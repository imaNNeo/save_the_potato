extension ListExtension<T> on List<T> {
  List<T> randomOrder() {
    final List<T> copy = List<T>.from(this);
    copy.shuffle();
    return copy;
  }
}