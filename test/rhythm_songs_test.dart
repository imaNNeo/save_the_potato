import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_songs.dart';

Map<int, int> tierCounts(MelodyPhrase phrase) {
  final counts = <int, int>{};
  for (final note in phrase.notes) {
    counts[note.tier] = (counts[note.tier] ?? 0) + 1;
  }
  return counts;
}

void main() {
  songFormTests();
  test('every phrase is as busy as the original one', () {
    final home = tierCounts(RhythmSongs.home);
    for (final phrase in RhythmSongs.phrases) {
      expect(tierCounts(phrase), home, reason: phrase.name);
    }
  });

  test('every phrase fits the 8 bar loop and has every downbeat', () {
    for (final phrase in RhythmSongs.phrases) {
      for (final note in phrase.notes) {
        expect(note.bar, inInclusiveRange(0, RhythmSongs.bars - 1));
        expect(note.beat, inInclusiveRange(0, 3.5));
      }
      final downbeats = phrase.notes.where((n) => n.tier == 0);
      expect(downbeats.map((n) => n.bar).toSet(), {
        for (var b = 0; b < RhythmSongs.bars; b++) b,
      }, reason: phrase.name);
      final ice = phrase.notes.where(phrase.isIce).length;
      expect(ice, inInclusiveRange(10, 21), reason: phrase.name);
    }
  });

  test('the melody climbs from stage to stage', () {
    double topOf(SongStage stage) => stage.phrases
        .expand((p) => p.notes)
        .map((n) => n.midi.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final stages = RhythmSongs.stages;
    for (var i = 1; i < stages.length; i++) {
      expect(stages[i].from, greaterThan(stages[i - 1].from));
      expect(topOf(stages[i]), greaterThanOrEqualTo(topOf(stages[i - 1])));
    }
  });

  test('the first minute swaps phrases, and the peak waits a few minutes', () {
    double difficultyAt(double s) =>
        GameState(difficultyTimePassed: s).difficulty;
    final early = RhythmSongs.stageFor(difficultyAt(30));
    expect(early.phrases.toSet().length, greaterThan(1));
    expect(early.layers, isEmpty);
    expect(RhythmSongs.stageFor(difficultyAt(120)).layers, isEmpty);
    expect(
      RhythmSongs.stageFor(difficultyAt(480)).phrases,
      contains(RhythmSongs.peak),
    );
  });
}

void songFormTests() {
  test(
    'the song has a busy chorus and a breather, and starts with a verse',
    () {
      expect(RhythmSongs.sectionFor(0), SongSection.verse);
      expect(RhythmSongs.form, contains(SongSection.chorus));
      expect(RhythmSongs.form, contains(SongSection.breather));
      expect(
        SongSection.breather.mutedStemsOf(RhythmSongs.song),
        contains('kick'),
      );
      expect(SongSection.chorus.layersOver(const []), ['hats16']);
      expect(SongSection.chorus.layersOver(const ['hats16']), [
        'hats16',
        'arp',
      ]);
      expect(SongSection.breather.layersOver(const ['hats16']), isEmpty);
    },
  );

  test('harmony and pair notes are tones of the bar chord', () {
    for (final phrase in RhythmSongs.phrases) {
      for (final note in phrase.notes) {
        final chord = RhythmSongs.chordOfBar(note.bar);
        final harmony = RhythmSongs.harmonyBelow(note.midi, note.bar);
        expect(note.midi - harmony, inInclusiveRange(3, 14));
        expect(chord, contains(harmony % 12));
      }
    }
    for (var bar = 0; bar < RhythmSongs.bars; bar++) {
      final root = RhythmSongs.rootFrom(46, bar);
      expect(root, inInclusiveRange(46, 57));
      expect(root % 12, RhythmSongs.chordOfBar(bar).first);
    }
  });
}
