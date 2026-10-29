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

  test('quick blocks make a chain that charges and ends after a pause', () {
    final streak = DefendStreak();
    for (var i = 0; i < 4; i++) {
      streak.block();
      expect(streak.update(0.3), 0);
    }
    expect(streak.chain, 4);
    expect(streak.targetCharge, greaterThan(0));
    expect(streak.charge, greaterThan(0));

    // The orbs stop coming, the chain is over once
    expect(streak.update(0.5), 4);
    expect(streak.chain, 0);
    expect(streak.update(0.5), 0);
    for (var i = 0; i < 120; i++) {
      streak.update(1 / 60);
    }
    expect(streak.charge, closeTo(0, 0.01));

    // Slow blocks never chain
    streak.block();
    streak.update(1);
    streak.block();
    expect(streak.chain, 1);
    expect(streak.targetCharge, 0);
  });

  test('a long chain is fully charged, getting hit drops it', () {
    final streak = DefendStreak();
    for (var i = 0; i < DefendStreak.fullChain + 2; i++) {
      streak.block();
      streak.update(0.1);
    }
    expect(streak.targetCharge, 1);
    streak.reset();
    expect(streak.chain, 0);
    expect(streak.update(1), 0);
  });
}
