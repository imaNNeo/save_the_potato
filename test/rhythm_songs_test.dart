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
