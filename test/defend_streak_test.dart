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

  test('quick blocks make a chain that ends after a pause', () {
    final streak = DefendStreak();
    for (var i = 0; i < 4; i++) {
      streak.block();
      expect(streak.update(0.3), 0);
    }
    expect(streak.chain, 4);

    // The orbs stop coming, the chain is over once
    expect(streak.update(0.5), 4);
    expect(streak.chain, 0);
    expect(streak.update(0.5), 0);

    // Slow blocks never chain
    streak.block();
    streak.update(1);
    streak.block();
    expect(streak.chain, 1);
  });

  test('every block jolts the power up and it drains quickly', () {
    final streak = DefendStreak();
    streak.block();
    final jolt = streak.power;
    expect(jolt, greaterThan(0.25));

    streak.update(1);
    expect(streak.power, lessThan(jolt * 0.4));

    // Blocking again and again keeps it high
    for (var i = 0; i < 10; i++) {
      streak.block();
      streak.update(0.3);
    }
    expect(streak.power, greaterThan(0.6));
    expect(streak.power, lessThanOrEqualTo(1));

    // A hot streak gives bigger jolts
    final cold = DefendStreak()..block();
    final hot = DefendStreak();
    for (var i = 0; i < 40; i++) {
      hot.block();
      hot.update(5);
    }
    hot.block();
    expect(hot.power, greaterThan(cold.power));
  });

  test('getting hit drops the streak, chain and power', () {
    final streak = DefendStreak();
    for (var i = 0; i < 5; i++) {
      streak.block();
      streak.update(0.1);
    }
    streak.reset();
    expect(streak.count, 0);
    expect(streak.chain, 0);
    expect(streak.power, 0);
    expect(streak.update(1), 0);
  });
}
