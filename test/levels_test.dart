import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/rhythm/level_songs.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_songs.dart';

void main() {
  test('there are 10 levels, each about 3 minutes, with no breather', () {
    expect(LevelSongs.all, hasLength(Levels.count));
    for (final song in LevelSongs.all) {
      expect(song.endless, isFalse);
      expect(song.durationSeconds, inInclusiveRange(150, 210));
      expect(song.form, isNot(contains(SongSection.breather)));
    }
  });

  test('the generated levels get faster', () {
    var bpm = 0.0;
    for (final song in LevelSongs.all.where((s) => !s.fullMelody)) {
      expect(song.bpm, greaterThan(bpm));
      bpm = song.bpm;
    }
  });

  test('every note of a level fits in its bars', () {
    for (final song in LevelSongs.all) {
      for (final phrase in song.phrases) {
        for (final note in phrase.notes) {
          expect(note.bar, inInclusiveRange(0, song.bars - 1));
          expect(note.beat, greaterThanOrEqualTo(0));
          expect(note.beat, lessThan(song.beatsPerBar), reason: song.name);
        }
      }
    }
  });

  test('a generated level phrase is as busy as the infinite song\'s', () {
    // 8 downbeats, 17 notes on a beat and 6 between beats, so the
    // difficulty lets the same number of notes in. The tunes of levels
    // 1-6 play every note as written instead.
    for (final song in LevelSongs.all.where((s) => !s.fullMelody)) {
      for (final phrase in song.phrases) {
        final counts = <int, int>{};
        for (final note in phrase.notes) {
          counts[note.tier] = (counts[note.tier] ?? 0) + 1;
        }
        expect(counts, {0: 8, 1: 17, 2: 6}, reason: song.name);
      }
    }
  });

  test('levels 1 to 6 play a whole tune note for note', () {
    for (final song in LevelSongs.all.take(6)) {
      expect(song.fullMelody, isTrue, reason: song.name);
      expect(song.phrases, hasLength(1));
      expect(song.chords, hasLength(song.bars));
    }
  });

  test('a level\'s stage follows how far into the song it is', () {
    final song = LevelSongs.all.first;
    final first = song.stageFor(loop: 0, difficulty: 1);
    final last = song.stageFor(loop: song.form.length - 1, difficulty: 0);
    expect(first, song.stages.first);
    expect(last, song.stages.last);
    expect(song.sectionFor(999), song.form.last);
  });

  test('every level song has its stems', () {
    for (final song in LevelSongs.all) {
      for (final stem in song.allStems) {
        final file = File('assets/audio/${song.assetDir}/stem_$stem.ogg');
        expect(file.existsSync(), isTrue, reason: file.path);
      }
    }
  });

  test('each level is harder than the one before, and ramps up', () {
    for (var level = 1; level <= Levels.count; level++) {
      expect(
        Levels.difficultyAt(level, 1),
        greaterThan(Levels.difficultyAt(level, 0)),
      );
      if (level > 1) {
        expect(
          Levels.difficultyAt(level, 0),
          greaterThan(Levels.difficultyAt(level - 1, 0)),
        );
      }
    }
    expect(Levels.difficultyAt(1, 0), 0);
    expect(Levels.difficultyAt(Levels.count, 1), lessThan(1));
  });

  test('a level uses its own song and difficulty', () {
    const infinite = GameState();
    expect(infinite.song, RhythmSongs.song);
    final level = GameState(level: 3, difficultyTimePassed: 0);
    expect(level.song, LevelSongs.all[2]);
    expect(level.difficulty, Levels.difficultyAt(3, 0));
  });

  test('only the next level after the cleared ones is open', () {
    expect(Levels.isOpen(1, 0), isTrue);
    expect(Levels.isOpen(2, 0), isFalse);
    expect(Levels.isOpen(4, 3), isTrue);
    expect(Levels.nextAfter(10), Levels.count);
  });
}
