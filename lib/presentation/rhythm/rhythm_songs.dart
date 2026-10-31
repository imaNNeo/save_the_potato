/// The new 120 BPM song in D minor (Dm, Bb, F, C), as 8 bar looping stems
/// in `assets/audio/rhythm/`, plus the melody the shield plays over it.
class RhythmSongs {
  static const bpm = 120.0;
  static const beatSeconds = 60 / bpm;
  static const bars = 8;
  static const loopSeconds = bars * 4 * beatSeconds;

  /// The lead the shield plays in "Shield plays the melody"
  static const melody = [
    MelodyNote(0, 0, 69),
    MelodyNote(0, 1, 74),
    MelodyNote(0, 2, 76),
    MelodyNote(0, 2.5, 77),
    MelodyNote(1, 0, 74),
    MelodyNote(1, 1.5, 74),
    MelodyNote(1, 2, 72),
    MelodyNote(1, 3, 70),
    MelodyNote(2, 0, 69),
    MelodyNote(2, 1, 72),
    MelodyNote(2, 2, 77),
    MelodyNote(2, 2.5, 76),
    MelodyNote(3, 0, 76),
    MelodyNote(3, 1, 72),
    MelodyNote(3, 2, 67),
    MelodyNote(4, 0, 69),
    MelodyNote(4, 1, 74),
    MelodyNote(4, 2, 76),
    MelodyNote(4, 2.5, 77),
    MelodyNote(5, 0, 79),
    MelodyNote(5, 1, 77),
    MelodyNote(5, 1.5, 76),
    MelodyNote(5, 2, 74),
    MelodyNote(6, 0, 72),
    MelodyNote(6, 1, 69),
    MelodyNote(6, 2, 72),
    MelodyNote(6, 3, 77),
    MelodyNote(7, 0, 76),
    MelodyNote(7, 1.5, 79),
    MelodyNote(7, 2, 76),
    MelodyNote(7, 3, 73),
  ];
}

class MelodyNote {
  const MelodyNote(this.bar, this.beat, this.midi);

  final int bar;
  final double beat;
  final int midi;

  /// 0: first beat of the bar, 1: on a beat, 2: between beats
  int get tier => beat == 0 ? 0 : (beat == beat.floorToDouble() ? 1 : 2);
}
