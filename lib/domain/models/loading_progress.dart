/// Adds up the progress of a few loading steps that run at the same time.
///
/// Every step says up front how many parts it has, so the total never
/// grows and the progress never goes back.
class LoadingProgress {
  LoadingProgress(Map<String, int> steps)
    : _total = {
        for (final e in steps.entries) e.key: e.value < 1 ? 1 : e.value,
      };

  final Map<String, int> _total;
  final _done = <String, int>{};

  /// [done] parts of [step] are loaded. Unknown steps are ignored.
  void report(String step, int done) {
    final total = _total[step];
    if (total == null) return;
    final clamped = done.clamp(0, total);
    if (clamped > (_done[step] ?? 0)) _done[step] = clamped;
  }

  /// All of [step] is loaded
  void finish(String step) => report(step, _total[step] ?? 0);

  /// From 0 (nothing loaded) to 1 (everything loaded)
  double get value {
    final total = _total.values.fold(0, (a, b) => a + b);
    if (total == 0) return 1;
    final done = _done.values.fold(0, (a, b) => a + b);
    return done / total;
  }

  bool get isDone => value >= 1;
}
