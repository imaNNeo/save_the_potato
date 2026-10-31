/// Beat times of `bg_120_140c_bpm.ogg` (it speeds up from 120 to 135 BPM),
/// with the strongest pitch class around each beat. Made offline from the
/// audio, see `assets/audio/rhythm/bg_beats.json`.
class BeatMap {
  BeatMap({
    required this.duration,
    required this.loopStart,
    required List<double> beats,
    required this.pitches,
    required this.chords,
  }) : _beats = beats,
       _firstLoopBeat = beats.indexWhere((b) => b >= loopStart);

  factory BeatMap.fromJson(Map<String, dynamic> json) => BeatMap(
    duration: (json['duration'] as num).toDouble(),
    loopStart: (json['loopStart'] as num).toDouble(),
    beats: [for (final b in json['beats'] as List) (b as num).toDouble()],
    pitches: [for (final p in json['pitch'] as List) p as int],
    chords: [
      for (final c in json['chord'] as List)
        [for (final p in c as List) p as int],
    ],
  );

  final double duration;
  final double loopStart;
  final List<double> _beats;

  /// Strongest pitch class (0 = C) around each beat
  final List<int> pitches;

  /// The three strongest pitch classes around each beat, low to high
  final List<List<int>> chords;
  final int _firstLoopBeat;

  double get _loopLength => duration - loopStart;

  int get _loopBeats => _beats.length - _firstLoopBeat;

  /// Index into the file's beats, and how many loops were played before it
  (int, int) _locate(int beat) {
    if (beat < _beats.length) {
      return (beat, 0);
    }
    final j = beat - _beats.length;
    return (_firstLoopBeat + j % _loopBeats, j ~/ _loopBeats + 1);
  }

  /// Time of [beat] counted from the start of the music, across loops
  double beatTime(int beat) {
    final (i, loops) = _locate(beat);
    return _beats[i] + loops * _loopLength;
  }

  int pitchAt(int beat) => pitches[_locate(beat).$1];

  List<int> chordAt(int beat) => chords[_locate(beat).$1];
}
