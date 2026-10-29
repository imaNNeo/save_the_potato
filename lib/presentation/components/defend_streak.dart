import 'dart:math';

/// Counts the orbs blocked in a row and how strong that makes the shields.
///
/// [heat] goes from 0 to 1, it climbs quickly with the first blocks and
/// slows down after (about 0.5 at 10 blocks, 0.9 at 35).
///
/// Every block also gives the shields a jolt of [power] that drains fast, so
/// it only stays high while the orbs keep coming and getting blocked. The
/// hotter the streak, the bigger the jolt.
///
/// Blocks that come quickly one after another make a [chain].
class DefendStreak {
  /// Every this many blocks in a row is celebrated
  static const milestoneEvery = 10;

  /// Blocks closer than this (in seconds) are in the same chain
  static const chainWindow = 0.75;

  /// A chain this long releases the most
  static const fullChain = 6;

  /// How fast [power] drains (per second)
  static const powerDrain = 1.3;

  int _count = 0;
  double _heat = 0;
  int _chain = 0;
  double _sinceBlock = double.infinity;
  double _power = 0;

  int get count => _count;

  /// Smoothly follows [targetHeat]
  double get heat => _heat;

  double get targetHeat => 1 - exp(-_count / 15);

  /// Blocks in the current chain, 0 when there is none
  int get chain => _chain;

  /// From 0 to 1, jumps up on every block and drains quickly
  double get power => _power;

  /// Returns true when the streak reaches a milestone
  bool block() {
    _count++;
    _chain = _sinceBlock <= chainWindow ? _chain + 1 : 1;
    _sinceBlock = 0;
    _power = min(1.0, _power + 0.3 + 0.25 * targetHeat);
    return _count % milestoneEvery == 0;
  }

  /// An orb got through, the streak, the chain and the power are gone
  void reset() {
    _count = 0;
    _chain = 0;
    _power = 0;
  }

  /// Returns the length of the chain that just ended, or 0
  int update(double dt) {
    // Heats up quickly, cools down a bit slower
    final rate = targetHeat > _heat ? 5.0 : 3.0;
    _heat += (targetHeat - _heat) * (1 - exp(-rate * dt));
    _power *= exp(-powerDrain * dt);

    var ended = 0;
    _sinceBlock += dt;
    if (_chain > 0 && _sinceBlock > chainWindow) {
      ended = _chain;
      _chain = 0;
    }
    return ended;
  }
}
