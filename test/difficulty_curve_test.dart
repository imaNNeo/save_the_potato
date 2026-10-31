import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

double difficultyAt(double seconds) =>
    GameState(difficultyTimePassed: seconds).difficulty;

void main() {
  test('difficulty climbs gently and never goes down over time', () {
    var previous = -1.0;
    for (var s = 0.0; s <= 600; s += 5) {
      final d = difficultyAt(s);
      expect(d, greaterThanOrEqualTo(previous));
      previous = d;
    }
    expect(difficultyAt(0), 0);
    expect(difficultyAt(600), 1);
  });

  test('two minutes in is still below half the peak', () {
    expect(difficultyAt(60), closeTo(0.21, 0.03));
    expect(difficultyAt(120), lessThan(0.45));
    expect(difficultyAt(300), lessThan(0.9));
  });
}
