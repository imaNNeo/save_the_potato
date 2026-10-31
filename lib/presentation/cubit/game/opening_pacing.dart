import 'dart:math';

/// Candidate pacings for the first minute, while we pick one. The web build
/// reads it from `?opening=` in the page URL.
enum OpeningPacing {
  /// Waves are a dice roll that can't start before about 0:45
  today,

  /// A wave director: the first wave at 0:20, then one every 25-30s of calm
  /// play, each a bit bigger
  director,

  /// [director], and the calm phase breathes: a quicker push, then a rest
  breathing,

  /// [director], and from 0:10 some spawns are a fire and an ice orb at once
  doubles;

  static final OpeningPacing current = OpeningPacing.values.firstWhere(
    (pacing) => pacing.name == Uri.base.queryParameters['opening'],
    orElse: () => OpeningPacing.today,
  );

  bool get hasDirector => this != OpeningPacing.today;

  /// Seconds of calm play before the first wave
  static const firstWaveAfter = 20.0;

  /// Seconds of calm play between waves after the first one
  static double nextWaveAfter(Random rnd) => 25 + rnd.nextDouble() * 5;

  /// How many portal pairs the [waveIndex]th wave has (0 is the first)
  static int waveSpawnerCount(int waveIndex, Random rnd) =>
      waveIndex < 3 ? waveIndex + 1 : 3 + rnd.nextInt(3);

  /// [breathing]: scales the spawn interval, 6s of push then 3s of rest
  static double breathingFactor(double calmTime) =>
      calmTime % 9 < 6 ? 0.75 : 1.6;

  /// [doubles]: the chance that a spawn after 0:10 is a pair
  static double doubleChance(double levelTime) => levelTime < 10 ? 0 : 0.25;
}
