import 'package:save_the_potato/presentation/rhythm/rhythm_mode.dart';

/// The new 120 BPM song in D minor (Dm, Bb, F, C), as 8 bar looping stems
/// in `assets/audio/rhythm/`, plus the parts the shield plays over it.
class RhythmSongs {
  static const bpm = 120.0;
  static const beatSeconds = 60 / bpm;
  static const bars = 8;
  static const loopSeconds = bars * 4 * beatSeconds;

  static const _chords = [
    Chord(root: 38, voicing: [62, 65, 69]), // Dm
    Chord(root: 34, voicing: [62, 65, 70]), // Bb
    Chord(root: 41, voicing: [60, 65, 69]), // F
    Chord(root: 36, voicing: [60, 64, 67]), // C
  ];

  static Chord chordOfBar(int bar) => _chords[bar % 4];

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

  /// "Fire drum, ice bell": one bar per string on an 8th note grid, per tier
  /// of difficulty. F = fire boom, I = ice ting.
  static const drumPatterns = [
    ['F.......', 'I.......', 'F.......', 'I...I...'],
    ['F...I...', 'F..F....', 'I...I...', 'F.I.....'],
    [
      'F..F..I.',
      'F..F..II',
      'F.I.F.I.',
      'F.IF.FI.',
      'F..F..I.',
      'F..F.III',
      'FIF.FIF.',
      'F.F.IIII',
    ],
  ];

  static const melodyLayers = {'kick', 'pad', 'hats', 'bass', 'claps'};

  /// No kick: the fire blocks are the kick
  static const drumBellLayers = {'pad', 'hats', 'bass', 'claps', 'hats16'};

  /// Streak needed for each extra layer in "Streak builds the song"
  static const _streakLayers = {
    'hats': 4,
    'bass': 8,
    'claps': 14,
    'arp': 20,
    'hats16': 28,
  };

  static Iterable<int> get streakUnlocks => _streakLayers.values;

  static Set<String> streakLayersFor(int streak) => {
    for (final e in _streakLayers.entries)
      if (streak >= e.value) e.key,
  };

  /// Layers that play whatever happens
  static Set<String> alwaysOn(RhythmMode mode) => switch (mode) {
    RhythmMode.melody => melodyLayers,
    RhythmMode.drumBell => drumBellLayers,
    RhythmMode.streakSong => const {'kick', 'pad'},
    _ => const {},
  };
}

class Chord {
  const Chord({required this.root, required this.voicing});

  final int root;
  final List<int> voicing;

  /// Chord tones over two octaves; streak notes climb through them
  List<int> get climbPool =>
      [...voicing, for (final v in voicing) v + 12]..sort();
}

class MelodyNote {
  const MelodyNote(this.bar, this.beat, this.midi);

  final int bar;
  final double beat;
  final int midi;

  /// 0: first beat of the bar, 1: on a beat, 2: between beats
  int get tier => beat == 0 ? 0 : (beat == beat.floorToDouble() ? 1 : 2);
}
