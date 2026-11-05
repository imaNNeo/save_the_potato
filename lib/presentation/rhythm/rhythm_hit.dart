/// The melody note an orb plays when the shield blocks it
class RhythmHit {
  const RhythmHit({
    required this.timbre,
    this.midi = 60,
    this.land = 0,
    this.volume = 1,
    this.companion = false,
  });

  /// fire or ice (see `AudioHelper.playNote`)
  final String timbre;
  final int midi;

  /// Song time it should land at
  final double land;

  final double volume;

  /// Lands together with a melody orb to make a chord. It is there to make
  /// the screen busy, not to make the game harder: if it gets through, it
  /// does no harm (the melody orb it came with already counts).
  final bool companion;
}
