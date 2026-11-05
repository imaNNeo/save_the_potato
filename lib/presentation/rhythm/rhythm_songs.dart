/// The 120 BPM song in D minor (Dm, Bb, F, C, one chord per bar), as 8 bar
/// looping stems in `assets/audio/rhythm/`, plus the melody the shield plays
/// over it.
///
/// The melody is not one loop. It is a set of 8 bar [MelodyPhrase]s, and
/// every pass of the backing loop plays the next phrase of the current
/// [SongStage]. Early stages swap between two phrases with different
/// shapes, and later stages climb higher, lean on tense notes, and bring in
/// extra backing layers.
class RhythmSongs {
  static const bpm = 120.0;
  static const beatSeconds = 60 / bpm;
  static const bars = 8;
  static const loopSeconds = bars * 4 * beatSeconds;

  /// Backing stems that start silent and fade in for the later stages
  static const extraLayers = ['hats16', 'arp'];

  /// The stage for [difficulty]
  static SongStage stageFor(double difficulty) =>
      stages.lastWhere((s) => difficulty >= s.from);

  static const stages = [
    // About the first minute: two phrases that answer each other
    SongStage(from: 0, phrases: [home, valley]),
    // Up to about two minutes: the lift creeps in between them
    SongStage(from: 0.2, phrases: [home, lift, valley, lift]),
    // Higher and tenser, with 16th hats under it
    SongStage(from: 0.45, phrases: [lift, tense], layers: ['hats16']),
    // The top of the range, with the arp driving it
    SongStage(from: 0.7, phrases: [tense, peak], layers: ['hats16', 'arp']),
  ];

  /// The original lead: middle register, small arcs
  static const home = MelodyPhrase(
    'home',
    iceFrom: 74,
    notes: [
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
    ],
  );

  /// The answer: falls from F5 down to a low E4, then jumps up to A5
  static const valley = MelodyPhrase(
    'valley',
    iceFrom: 74,
    notes: [
      MelodyNote(0, 0, 77),
      MelodyNote(0, 1, 76),
      MelodyNote(0, 2, 74),
      MelodyNote(0, 3, 69),
      MelodyNote(1, 0, 70),
      MelodyNote(1, 1.5, 74),
      MelodyNote(1, 2, 77),
      MelodyNote(2, 0, 72),
      MelodyNote(2, 1, 69),
      MelodyNote(2, 2, 65),
      MelodyNote(2, 2.5, 67),
      MelodyNote(3, 0, 64),
      MelodyNote(3, 2, 72),
      MelodyNote(3, 2.5, 74),
      MelodyNote(3, 3, 76),
      MelodyNote(4, 0, 81),
      MelodyNote(4, 1, 77),
      MelodyNote(4, 1.5, 76),
      MelodyNote(4, 2, 74),
      MelodyNote(5, 0, 74),
      MelodyNote(5, 1, 70),
      MelodyNote(5, 2, 74),
      MelodyNote(5, 2.5, 77),
      MelodyNote(6, 0, 81),
      MelodyNote(6, 1, 79),
      MelodyNote(6, 2, 77),
      MelodyNote(6, 3, 72),
      MelodyNote(7, 0, 76),
      MelodyNote(7, 1.5, 72),
      MelodyNote(7, 2, 67),
      MelodyNote(7, 3, 73),
    ],
  );

  /// The home shape a third higher, reaching for Bb5 and C6
  static const lift = MelodyPhrase(
    'lift',
    iceFrom: 77,
    notes: [
      MelodyNote(0, 0, 74),
      MelodyNote(0, 1, 77),
      MelodyNote(0, 2, 81),
      MelodyNote(0, 2.5, 79),
      MelodyNote(1, 0, 77),
      MelodyNote(1, 1.5, 74),
      MelodyNote(1, 2, 77),
      MelodyNote(1, 3, 82),
      MelodyNote(2, 0, 81),
      MelodyNote(2, 1, 77),
      MelodyNote(2, 2, 72),
      MelodyNote(2, 2.5, 74),
      MelodyNote(3, 0, 76),
      MelodyNote(3, 1, 79),
      MelodyNote(3, 2, 84),
      MelodyNote(4, 0, 81),
      MelodyNote(4, 1, 77),
      MelodyNote(4, 2, 74),
      MelodyNote(4, 2.5, 77),
      MelodyNote(5, 0, 82),
      MelodyNote(5, 1, 81),
      MelodyNote(5, 1.5, 77),
      MelodyNote(5, 2, 74),
      MelodyNote(6, 0, 77),
      MelodyNote(6, 1, 81),
      MelodyNote(6, 2, 84),
      MelodyNote(6, 3, 81),
      MelodyNote(7, 0, 79),
      MelodyNote(7, 1.5, 76),
      MelodyNote(7, 2, 72),
      MelodyNote(7, 3, 73),
    ],
  );

  /// High and restless: Bb over Dm, a flat 7th over C, C# pulling to D6
  static const tense = MelodyPhrase(
    'tense',
    iceFrom: 81,
    notes: [
      MelodyNote(0, 0, 74),
      MelodyNote(0, 1, 81),
      MelodyNote(0, 2, 82),
      MelodyNote(0, 2.5, 81),
      MelodyNote(0, 3, 77),
      MelodyNote(1, 0, 79),
      MelodyNote(1, 1, 77),
      MelodyNote(1, 2, 82),
      MelodyNote(1, 3, 86),
      MelodyNote(2, 0, 84),
      MelodyNote(2, 1.5, 81),
      MelodyNote(2, 2, 84),
      MelodyNote(2, 3, 79),
      MelodyNote(3, 0, 79),
      MelodyNote(3, 2, 84),
      MelodyNote(3, 2.5, 82),
      MelodyNote(3, 3, 85),
      MelodyNote(4, 0, 86),
      MelodyNote(4, 1, 81),
      MelodyNote(4, 1.5, 77),
      MelodyNote(4, 2, 74),
      MelodyNote(5, 0, 82),
      MelodyNote(5, 1, 79),
      MelodyNote(5, 2, 77),
      MelodyNote(5, 3, 86),
      MelodyNote(6, 0, 84),
      MelodyNote(6, 2.5, 86),
      MelodyNote(6, 3, 88),
      MelodyNote(7, 0, 88),
      MelodyNote(7, 1.5, 84),
      MelodyNote(7, 3, 85),
    ],
  );

  /// The top: D6 and E6, falling runs that jump straight back up
  static const peak = MelodyPhrase(
    'peak',
    iceFrom: 82,
    notes: [
      MelodyNote(0, 0, 86),
      MelodyNote(0, 1, 81),
      MelodyNote(0, 1.5, 84),
      MelodyNote(0, 2, 86),
      MelodyNote(0, 3, 88),
      MelodyNote(1, 0, 86),
      MelodyNote(1, 1, 82),
      MelodyNote(1, 2, 77),
      MelodyNote(1, 3, 74),
      MelodyNote(2, 0, 77),
      MelodyNote(2, 1, 81),
      MelodyNote(2, 2, 84),
      MelodyNote(2, 3, 88),
      MelodyNote(3, 0, 84),
      MelodyNote(3, 1.5, 88),
      MelodyNote(3, 2, 84),
      MelodyNote(3, 3, 85),
      MelodyNote(4, 0, 86),
      MelodyNote(4, 1.5, 84),
      MelodyNote(4, 2, 81),
      MelodyNote(4, 2.5, 77),
      MelodyNote(5, 0, 82),
      MelodyNote(5, 1, 86),
      MelodyNote(5, 2, 82),
      MelodyNote(6, 0, 72),
      MelodyNote(6, 1, 77),
      MelodyNote(6, 1.5, 81),
      MelodyNote(6, 2, 84),
      MelodyNote(6, 2.5, 86),
      MelodyNote(7, 0, 88),
      MelodyNote(7, 3, 85),
    ],
  );

  static const phrases = [home, valley, lift, tense, peak];

  /// The form of the song, one [SongSection] per pass of the loop, like a
  /// real track: a verse, a busy chorus, the verse again, the chorus again,
  /// then a breather where the drums drop out, and around again.
  static const form = [
    SongSection.verse,
    SongSection.chorus,
    SongSection.verse,
    SongSection.chorus,
    SongSection.breather,
  ];

  static SongSection sectionFor(int loop) => form[loop % form.length];

  /// The chord of each bar of the 8 bar loop, as pitch classes (Dm, Bb, F,
  /// C, twice). The root comes first.
  static const chords = [
    [2, 5, 9],
    [10, 2, 5],
    [5, 9, 0],
    [0, 4, 7],
  ];

  static List<int> chordOfBar(int bar) => chords[bar % chords.length];

  /// A tone of the bar's chord a third or more below [melody], to stack
  /// under it
  static int harmonyBelow(int melody, int bar) {
    final chord = chordOfBar(bar);
    for (var midi = melody - 3; midi > melody - 15; midi--) {
      if (chord.contains(midi % 12)) {
        return midi;
      }
    }
    return melody - 12;
  }

  /// The root of the bar's chord, between [low] and [low] + 11
  static int rootFrom(int low, int bar) {
    final root = chordOfBar(bar).first;
    return low + (root - low) % 12;
  }
}

/// One part of the song's form. Each pass of the loop is one section. The
/// section changes how many melody notes come as orbs, how many orbs come
/// together for a note, and what the backing plays.
enum SongSection {
  /// The groove: the notes the difficulty allows, plus a few more on the
  /// beat. The first note of every bar comes as a fire and ice pair.
  verse(notesAhead: 0.08, pairsUpToTier: 0, triads: false),

  /// Busier and louder: a little more of the melody plays, every note on a
  /// beat brings a pair from the opposite side, every other bar opens with
  /// a harmony orb too, and the 16th hats join in. It looks busy, but the
  /// extra orbs land with their note and need no extra move.
  chorus(notesAhead: 0.15, pairsUpToTier: 1, triads: true),

  /// A breather: the drums drop out and only the first note of each bar
  /// comes, one orb at a time
  breather(notesAhead: -1, pairsUpToTier: -1, triads: false);

  const SongSection({
    required this.notesAhead,
    required this.pairsUpToTier,
    required this.triads,
  });

  /// How far ahead of the difficulty the melody notes join in. A note
  /// joins at a difficulty (see the rhythm director), and in this section
  /// it joins this much sooner. Below zero only the first note of each bar
  /// plays.
  final double notesAhead;

  /// Notes of this [MelodyNote.tier] or lower bring a pair orb of the other
  /// kind from the opposite side, which the other end of the shield blocks
  /// on its own
  final int pairsUpToTier;

  /// Whether the first note of every other bar also brings a harmony orb
  /// next to it
  final bool triads;

  /// Backing stems that drop out in this section
  List<String> get mutedStems =>
      this == breather ? const ['kick', 'claps', 'hats'] : const [];

  /// The extra backing layers this section plays over the stage's own
  List<String> layersOver(List<String> stageLayers) => switch (this) {
    verse => stageLayers,
    breather => const [],
    chorus => [
      ...RhythmSongs.extraLayers.where(
        (l) =>
            stageLayers.contains(l) ||
            l == 'hats16' ||
            // The arp joins the chorus once the stage has the 16th hats
            stageLayers.contains('hats16'),
      ),
    ],
  };
}

/// A stretch of the song from [from] difficulty on: the phrases it cycles
/// through, and which [RhythmSongs.extraLayers] play under them
class SongStage {
  const SongStage({
    required this.from,
    required this.phrases,
    this.layers = const [],
  });

  final double from;
  final List<MelodyPhrase> phrases;
  final List<String> layers;
}

/// 8 bars of melody. Every phrase has the same number of notes of each
/// [MelodyNote.tier], so switching phrases never changes how busy it gets.
class MelodyPhrase {
  const MelodyPhrase(this.name, {required this.iceFrom, required this.notes});

  final String name;

  /// Notes from this pitch up come as ice orbs and ring as bells, lower
  /// ones come as fire and sound an octave down. Set per phrase, so a high
  /// phrase still mixes both kinds.
  final int iceFrom;
  final List<MelodyNote> notes;

  bool isIce(MelodyNote note) => note.midi >= iceFrom;
}

class MelodyNote {
  const MelodyNote(this.bar, this.beat, this.midi);

  final int bar;
  final double beat;
  final int midi;

  /// 0: first beat of the bar, 1: on a beat, 2: between beats
  int get tier => beat == 0 ? 0 : (beat == beat.floorToDouble() ? 1 : 2);
}
