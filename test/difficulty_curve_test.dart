import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';

double difficultyAt(double seconds) =>
    GameState(difficultyTimePassed: seconds).difficulty;

double overdriveAt(double seconds) =>
    GameState(difficultyTimePassed: seconds).overdrive;

double speedAt(double seconds) =>
    const GameModeSingleSpawn().getSpawnOrbsMoveSpeed(
      difficultyAt(seconds),
      overdrive: overdriveAt(seconds),
    );

double warningAt(double seconds) => RingRift.formDurationFor(
  difficultyAt(seconds),
  overdrive: overdriveAt(seconds),
);

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

  test('overdrive starts at the peak and keeps it rising until 20 minutes', () {
    expect(overdriveAt(0), 0);
    expect(overdriveAt(480), 0);
    expect(overdriveAt(600), closeTo(1 / 6, 1e-9));
    expect(overdriveAt(840), closeTo(0.5, 1e-9));
    expect(overdriveAt(1200), 1);
    expect(overdriveAt(3000), 1);
  });

  test('orbs get faster and rifts warn shorter all the way to 20 minutes', () {
    var previousSpeed = 0.0;
    var previousWarning = double.infinity;
    for (var s = 0.0; s <= 1200; s += 5) {
      final speed = speedAt(s);
      final warning = warningAt(s);
      expect(speed, greaterThanOrEqualTo(previousSpeed));
      expect(warning, lessThanOrEqualTo(previousWarning));
      previousSpeed = speed;
      previousWarning = warning;
    }
    expect(speedAt(480), 200);
    expect(speedAt(600), greaterThan(205));
    expect(speedAt(1200), 250);
    expect(warningAt(1200), RingRift.overdriveFormDuration);
  });
}
