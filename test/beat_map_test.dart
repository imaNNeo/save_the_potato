import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/rhythm/beat_map.dart';

void main() {
  final map = BeatMap(
    duration: 10,
    loopStart: 6,
    beats: [0, 2, 4, 6, 8],
    pitches: [0, 1, 2, 3, 4],
    chords: [
      [0, 4, 7],
      [1, 5, 8],
      [2, 6, 9],
      [3, 7, 10],
      [4, 8, 11],
    ],
  );

  test('beats before the loop come straight from the file', () {
    expect(map.beatTime(0), 0);
    expect(map.beatTime(4), 8);
    expect(map.pitchAt(2), 2);
  });

  test('after the end it repeats the looped part, shifted by its length', () {
    // The loop is 6s to 10s and holds the beats at 6 and 8
    expect(map.beatTime(5), 10);
    expect(map.beatTime(6), 12);
    expect(map.beatTime(7), 14);
    expect(map.pitchAt(5), 3);
    expect(map.chordAt(6), [4, 8, 11]);
  });
}
