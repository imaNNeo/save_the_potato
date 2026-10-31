import 'package:flutter/foundation.dart';

/// Prototype 3: hand-made levels on a map. Each level is short, starts at its
/// own difficulty and throws its waves at fixed times. Hearts left at the end
/// give 1 to 3 stars, and stars unlock the next levels.
class LevelDef {
  const LevelDef({
    required this.seconds,
    required this.startDifficultyTime,
    this.waves = const [],
  });

  final double seconds;

  /// Where the difficulty curve starts, in seconds of the endless mode
  final double startDifficultyTime;

  /// (second, spawner count) pairs
  final List<(double, int)> waves;
}

class Levels extends ChangeNotifier {
  Levels._();

  static final instance = Levels._();

  static const all = [
    LevelDef(seconds: 20, startDifficultyTime: 0, waves: [(12, 1)]),
    LevelDef(seconds: 25, startDifficultyTime: 10, waves: [(8, 1), (18, 2)]),
    LevelDef(seconds: 30, startDifficultyTime: 20, waves: [(10, 2), (22, 2)]),
    LevelDef(seconds: 30, startDifficultyTime: 35, waves: [(6, 2), (20, 3)]),
    LevelDef(
      seconds: 35,
      startDifficultyTime: 45,
      waves: [(5, 2), (16, 2), (27, 3)],
    ),
    LevelDef(seconds: 35, startDifficultyTime: 60, waves: [(8, 3), (24, 3)]),
    LevelDef(
      seconds: 40,
      startDifficultyTime: 80,
      waves: [(6, 3), (18, 3), (30, 4)],
    ),
    LevelDef(seconds: 40, startDifficultyTime: 100, waves: [(5, 4), (22, 4)]),
    LevelDef(
      seconds: 45,
      startDifficultyTime: 130,
      waves: [(5, 3), (16, 4), (30, 5)],
    ),
    LevelDef(seconds: 45, startDifficultyTime: 160, waves: [(4, 5), (24, 5)]),
    LevelDef(
      seconds: 50,
      startDifficultyTime: 200,
      waves: [(4, 4), (18, 5), (34, 5)],
    ),
    LevelDef(
      seconds: 60,
      startDifficultyTime: 260,
      waves: [(3, 5), (20, 5), (40, 5)],
    ),
  ];

  /// Stars per level, 0 means not cleared yet
  final stars = List<int>.filled(all.length, 0);

  int current = 0;

  /// Set when the current level is finished, with the stars it earned
  int? result;

  LevelDef get level => all[current];

  int get totalStars => stars.fold(0, (a, b) => a + b);

  /// A level opens when the one before it is cleared
  bool isOpen(int index) => index == 0 || stars[index - 1] > 0;

  void select(int index) {
    current = index;
    result = null;
    notifyListeners();
  }

  void finish(int heartsLeft) {
    final earned = heartsLeft.clamp(1, 3);
    if (earned > stars[current]) {
      stars[current] = earned;
    }
    result = earned;
    notifyListeners();
  }

  /// For the video, so later levels can be shown without playing them all
  void unlockUpTo(int index) {
    for (var i = 0; i < index; i++) {
      if (stars[i] == 0) {
        stars[i] = 1 + (i * 7) % 3;
      }
    }
    notifyListeners();
  }
}
