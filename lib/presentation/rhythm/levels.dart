import 'dart:ui';

import 'level_songs.dart';
import 'rhythm_songs.dart';

/// The levels mode: 10 levels, one song each. A level is cleared when its
/// song ends, which opens the next one.
class Levels {
  Levels._();

  static const count = 10;

  static Song songOf(int level) => LevelSongs.all[level - 1];

  /// Whether [level] can be played after [cleared] levels are cleared
  static bool isOpen(int level, int cleared) => level <= cleared + 1;

  /// The next level to play after [cleared] levels are cleared
  static int nextAfter(int cleared) => (cleared + 1).clamp(1, count);

  /// Each level gets harder over its song, and starts and ends harder than
  /// the one before. Level 1 goes from 0 to 0.35, level 10 from 0.45 to
  /// 0.93 (the infinite mode reaches 1.0 after 8 minutes).
  static double difficultyAt(int level, double progress) {
    final i = (level - 1) / (count - 1);
    final start = lerpDouble(0.0, 0.45, i)!;
    final end = lerpDouble(0.35, 0.93, i)!;
    return lerpDouble(start, end, progress.clamp(0.0, 1.0))!;
  }
}
