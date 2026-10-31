/// The melody note an orb plays when the shield blocks it
class RhythmHit {
  const RhythmHit({required this.timbre, this.midi = 60, this.land = 0});

  /// fire or ice (see `AudioHelper.playNote`)
  final String timbre;
  final int midi;

  /// Song time it should land at
  final double land;
}
