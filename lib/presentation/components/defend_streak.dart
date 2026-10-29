import 'dart:math';

/// Counts the orbs blocked in a row and how hot that makes the shields.
///
/// [heat] goes from 0 to 1, it climbs quickly with the first blocks and
/// slows down after (about 0.5 at 10 blocks, 0.9 at 35).
///
/// Blocks that come quickly one after another also make a [chain], which
/// charges the shields up ([charge]) until the orbs stop coming.
class DefendStreak {
  /// Every this many blocks in a row is celebrated
  static const milestoneEvery = 10;

  /// Blocks closer than this (in seconds) are in the same chain
  static const chainWindow = 0.75;

  /// A chain this long is fully charged
  static const fullChain = 6;

  int _count = 0;
  double _heat = 0;
  int _chain = 0;
  double _sinceBlock = double.infinity;
  double _charge = 0;

  int get count => _count;

  /// Smoothly follows [targetHeat]
  double get heat => _heat;

  double get targetHeat => 1 - exp(-_count / 15);

  /// Blocks in the current chain, 0 when there is none
  int get chain => _chain;

  /// Smoothly follows [targetCharge]
  double get charge => _charge;

  /// From 0 to 1 while a chain of at least 2 blocks is going on
  double get targetCharge =>
      _chain < 2 ? 0 : min(1.0, (_chain - 1) / (fullChain - 1));

  /// Returns true when the streak reaches a milestone
  bool block() {
    _count++;
    _chain = _sinceBlock <= chainWindow ? _chain + 1 : 1;
    _sinceBlock = 0;
    return _count % milestoneEvery == 0;
  }

  /// An orb got through, the streak and the chain are gone
  void reset() {
    _count = 0;
    _chain = 0;
  }

  /// Returns the length of the chain that just ended, or 0
  int update(double dt) {
    // Heats up quickly, cools down a bit slower
    final rate = targetHeat > _heat ? 5.0 : 3.0;
    _heat += (targetHeat - _heat) * (1 - exp(-rate * dt));

    var ended = 0;
    _sinceBlock += dt;
    if (_chain > 0 && _sinceBlock > chainWindow) {
      ended = _chain;
      _chain = 0;
    }
    final chargeRate = targetCharge > _charge ? 14.0 : 4.0;
    _charge += (targetCharge - _charge) * (1 - exp(-chargeRate * dt));
    return ended;
  }
}
