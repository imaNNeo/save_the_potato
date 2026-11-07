import 'life_meter.dart';

/// How the potato feels about the life it has left. The potato's face shows
/// this instead of a life bar.
enum HealthMood {
  /// The next miss ends the run: pale, trembling, worried
  worried,

  /// In between: the usual happy dance
  normal,

  /// Plenty of life: eyes closed, swaying slowly, enjoying the music
  calm;

  /// At or above this much life the potato is [calm]
  static const calmAt = 0.7;

  /// Once [calm], it stays calm down to this much life, so it doesn't flicker
  /// right at the line
  static const calmUntil = 0.66;

  /// The mood for [life]. [current] is the mood it has now.
  static HealthMood of(double life, {HealthMood current = normal}) {
    if (life < LifeMeter.danger) {
      return worried;
    }
    final calmLine = current == calm ? calmUntil : calmAt;
    return life >= calmLine - 1e-9 ? calm : normal;
  }
}
