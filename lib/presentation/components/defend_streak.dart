import 'dart:math';

/// Counts the orbs blocked in a row and how hot that makes the shields.
///
/// [heat] goes from 0 to 1, it climbs quickly with the first blocks and
/// slows down after (about 0.5 at 10 blocks, 0.9 at 35).
class DefendStreak {
  /// Every this many blocks in a row is celebrated
  static const milestoneEvery = 10;

  int _count = 0;
  double _heat = 0;

  int get count => _count;

  /// Smoothly follows [targetHeat]
  double get heat => _heat;

  double get targetHeat => 1 - exp(-_count / 15);

  /// Returns true when the streak reaches a milestone
  bool block() {
    _count++;
    return _count % milestoneEvery == 0;
  }

  /// An orb got through, the streak is gone
  void reset() {
    _count = 0;
  }

  void update(double dt) {
    // Heats up quickly, cools down a bit slower
    final rate = targetHeat > _heat ? 5.0 : 3.0;
    _heat += (targetHeat - _heat) * (1 - exp(-rate * dt));
  }
}
