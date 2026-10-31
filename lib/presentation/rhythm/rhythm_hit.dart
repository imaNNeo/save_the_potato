/// What an orb plays when the shield blocks it, in the rhythm modes
class RhythmHit {
  const RhythmHit({
    required this.timbre,
    this.midi = 60,
    this.land = 0,
    this.silent = false,
  });

  /// fire or ice (see `AudioHelper.playNote`), or chord for
  /// today's shield chords, where [midi] is the chord number
  final String timbre;
  final int midi;

  /// Song time it should land at
  final double land;

  /// The twin of a mirrored wave orb; only one of the pair makes a sound
  final bool silent;
}
