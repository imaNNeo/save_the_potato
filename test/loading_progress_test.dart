import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/models/loading_progress.dart';

void main() {
  test('adds up the parts of every step', () {
    final progress = LoadingProgress({'a': 1, 'b': 3});
    expect(progress.value, 0);
    progress.report('b', 1);
    expect(progress.value, 0.25);
    progress.finish('a');
    expect(progress.value, 0.5);
    progress.report('b', 3);
    expect(progress.isDone, isTrue);
  });

  test('never goes back or past the end', () {
    final progress = LoadingProgress({'a': 4});
    progress.report('a', 3);
    progress.report('a', 1);
    expect(progress.value, 0.75);
    progress.report('a', 10);
    expect(progress.value, 1);
  });

  test('ignores steps it does not know', () {
    final progress = LoadingProgress({'a': 2});
    progress.report('other', 5);
    expect(progress.value, 0);
  });
}
