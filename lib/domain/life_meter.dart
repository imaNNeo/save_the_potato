import 'dart:math';

/// The rules of the life bar, which replaced the hearts.
///
/// Life goes from 0 to 1. Every blocked orb fills it a bit, every orb that
/// gets through takes half of it. An orb that gets through while the bar is
/// in the [danger] stage ends the game.
///
/// Starting at [start], that's 3 misses in a row to lose (like the 3 hearts),
/// and 4 from a full bar, so keeping it high keeps you safe.
class LifeMeter {
  /// Where the bar starts
  static const start = 0.5;

  /// How much a blocked orb fills
  static const perBlock = 0.02;

  /// Below this, the next miss ends the game
  static const danger = 0.2;

  /// Where each stage starts, the first one is the [danger] stage
  static const stages = [0.0, danger, 0.5, 0.8, 1.0];

  static int get lastStage => stages.length - 1;

  static double afterBlock(double life) => min(1.0, life + perBlock);

  /// Returns 0 when the game is over
  static double afterMiss(double life) => life < danger ? 0.0 : life / 2;

  static int stageOf(double life) {
    for (var i = stages.length - 1; i > 0; i--) {
      // A tiny margin so 0.8 made of 0.05 steps still counts as 0.8
      if (life >= stages[i] - 1e-9) {
        return i;
      }
    }
    return 0;
  }
}
