import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/components/defend_streak.dart';

void main() {
  test('every 10th block in a row is a milestone', () {
    final streak = DefendStreak();
    final milestones = [
      for (var i = 1; i <= 25; i++)
        if (streak.block()) i,
    ];
    expect(milestones, [10, 20]);
    expect(streak.count, 25);
  });

  test('heat climbs with the streak and stays below 1', () {
    final streak = DefendStreak();
    var previous = streak.targetHeat;
    expect(previous, 0);
    for (var i = 0; i < 60; i++) {
      streak.block();
      expect(streak.targetHeat, greaterThan(previous));
      expect(streak.targetHeat, lessThan(1));
      previous = streak.targetHeat;
    }
  });

  test('heat follows the streak smoothly and cools down after a hit', () {
    final streak = DefendStreak();
    for (var i = 0; i < 20; i++) {
      streak.block();
    }
    streak.update(1 / 60);
    expect(streak.heat, greaterThan(0));
    expect(streak.heat, lessThan(streak.targetHeat));

    for (var i = 0; i < 120; i++) {
      streak.update(1 / 60);
    }
    expect(streak.heat, closeTo(streak.targetHeat, 0.01));

    streak.reset();
    expect(streak.count, 0);
    final hot = streak.heat;
    streak.update(0.1);
    expect(streak.heat, lessThan(hot));
    for (var i = 0; i < 180; i++) {
      streak.update(1 / 60);
    }
    expect(streak.heat, closeTo(0, 0.01));
  });
}
