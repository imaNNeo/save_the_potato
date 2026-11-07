import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';
import 'package:save_the_potato/presentation/components/motivation_component.dart';
import 'package:save_the_potato/presentation/helpers/audio/sound_backend.dart';
import 'package:save_the_potato/presentation/helpers/audio/sound_backend_soloud.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_songs.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  Future<bool> get audioEnabled => _audioEnabled.value;

  /// flutter_soloud, or the browser's Web Audio on the web (see
  /// [SoundBackend])
  SoundBackend _backend = SoundBackend.create();

  late Object _heartHit, _orbHit1, _orbHit2, _tick;
  late Object _victory, _gameOver;
  final _words = <MotivationWordType, Object>{};

  /// One-shot notes pitched with the play speed, and the looping stems of
  /// the song the shield plays the melody over (the infinite song, or the
  /// level's). The extra layers start silent and fade in for the later
  /// stages of the song.
  Song _song = RhythmSongs.song;
  static const _layerFade = Duration(milliseconds: 1500);
  static const _noteBaseMidi = {'fire': 60, 'ice': 72};
  final _notes = <String, Object>{};
  final _stems = <String, Object>{};

  /// The stems of the infinite song stay loaded, a level's are loaded when
  /// it is picked
  final _infiniteStems = <String, Object>{};
  BackendMusic? _music;

  /// How many steps [initialize] reports, starting the engine counts as one
  static int get loadSteps =>
      1 +
      6 +
      _noteBaseMidi.length +
      RhythmSongs.song.allStems.length +
      MotivationWordType.values.length;

  /// Starts the audio engine and loads every sound. [onProgress] is called
  /// with how many of the [loadSteps] are done.
  Future<void> initialize({void Function(int done)? onProgress}) async {
    try {
      await _initialize(onProgress);
    } catch (e) {
      if (_backend is SoLoudBackend) {
        rethrow;
      }
      // The browser couldn't play or decode something: flutter_soloud
      // plays everything then
      debugPrint('Web Audio failed ($e), using flutter_soloud');
      _backend = SoLoudBackend();
      _notes.clear();
      _infiniteStems.clear();
      _stems.clear();
      _words.clear();
      await _initialize(onProgress);
    }
  }

  Future<void> _initialize(void Function(int done)? onProgress) async {
    var done = 0;
    void step() => onProgress?.call(++done);

    await _backend.init();
    step();

    const baseAssets = 'assets/audio';
    Future<Object> load(String path) async {
      final source = await _backend.load('$baseAssets/$path');
      step();
      return source;
    }

    // Loaded all at once, on the web every file is a separate download
    final heartHit = load('heart.wav');
    final orbHit1 = load('hit1.wav');
    final orbHit2 = load('hit2.wav');
    final victory = load('victory.mp3');
    final gameOver = load('game_over.wav');
    final tick = load('tick.ogg');
    final notes = {
      for (final name in _noteBaseMidi.keys)
        name: load('rhythm/note_$name.ogg'),
    };
    final stems = {
      for (final name in RhythmSongs.song.allStems)
        name: load('${RhythmSongs.song.assetDir}/stem_$name.ogg'),
    };
    final words = {
      for (var word in MotivationWordType.values)
        word: load('motivation/${word.assetName}'),
    };

    // Waits for all of them first, so one failing doesn't leave the
    // others' errors unhandled
    await Future.wait<Object?>([
      heartHit,
      orbHit1,
      orbHit2,
      victory,
      gameOver,
      tick,
      ...notes.values,
      ...stems.values,
      ...words.values,
    ]);
    _heartHit = await heartHit;
    _orbHit1 = await orbHit1;
    _orbHit2 = await orbHit2;
    _victory = await victory;
    _gameOver = await gameOver;
    _tick = await tick;
    for (final e in notes.entries) {
      _notes[e.key] = await e.value;
    }
    for (final e in stems.entries) {
      _infiniteStems[e.key] = await e.value;
    }
    _stems.addAll(_infiniteStems);
    for (final e in words.entries) {
      _words[e.key] = await e.value;
    }
  }

  /// Loads the stems of [song] (once), so the next
  /// [playBackgroundMusic] plays it
  /// Loads [song]'s stems. Calls run one after another, and a call that
  /// is no longer the latest one by the time its turn comes is skipped, so
  /// fast switching between levels loads only the song that was picked
  /// last.
  Future<void> useSong(Song song) {
    _wantedSong = song;
    final load = _songLoad
        // A load that failed must not stop every later one
        .catchError((_) {})
        .then((_) {
          if (song.id != _wantedSong.id) {
            return null;
          }
          return _loadSong(song);
        });
    _songLoad = load;
    return load;
  }

  Song _wantedSong = RhythmSongs.song;
  Future<void> _songLoad = Future.value();

  Future<void> _loadSong(Song song) async {
    if (song.id == _song.id) {
      return;
    }
    _stopStems();
    final previous = Map.of(_stems);
    _stems.clear();
    _song = song;
    if (song.id == RhythmSongs.song.id) {
      _stems.addAll(_infiniteStems);
    } else {
      for (final name in song.allStems) {
        _stems[name] = await _backend.load(
          'assets/audio/${song.assetDir}/stem_$name.ogg',
        );
      }
    }
    // Free the stems of the level played before
    for (final source in previous.values) {
      if (!_infiniteStems.containsValue(source) &&
          !_stems.containsValue(source)) {
        await _backend.dispose(source);
      }
    }
  }

  /// Starts the song's stems [startAt] seconds into the loop, fading in
  /// over [fadeIn] (a level's intro)
  void playBackgroundMusic({
    double startAt = 0,
    Duration fadeIn = Duration.zero,
  }) async {
    // The music of an earlier run never carries over into this one
    _stopStems();
    isPaused = false;
    if (!(await _audioEnabled.value)) {
      return;
    }
    _playStems(startAt: startAt, fadeIn: fadeIn);
  }

  /// A level's music played its last note: the stems stop right away (no
  /// fade out) and [chord] rings, the tonic the tune ends on
  void endMusic(List<int> chord) async {
    _stopStems();
    if (!(await _audioEnabled.value)) {
      return;
    }
    for (final midi in chord) {
      playNote('ice', midi, volume: 0.7);
    }
    if (chord.isNotEmpty) {
      // and its root low, as fire (an octave further down)
      playNote('fire', chord.first - 24, volume: 0.8);
    }
  }

  void setAudioEnabled(bool enabled) {
    _audioEnabled.setValue(enabled);
  }

  void pauseBackgroundMusic() {
    final music = _music;
    if (music == null) {
      return;
    }
    isPaused = true;
    music.setPaused(true);
  }

  void resumeBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (isPaused) {
      _music?.setPaused(false);
    } else {
      playBackgroundMusic();
    }
    isPaused = false;
  }

  Future<void> fadeAndStopBackgroundMusic(Duration duration) async {
    final music = _music;
    if (music == null) {
      return;
    }
    for (final name in _song.allStems) {
      music.fade(name, 0, duration);
    }
    await Future.delayed(duration);
    music.stop();
    if (_music == music) {
      _music = null;
    }
  }

  /// Where the music is now, in seconds of the file (it wraps when it loops).
  /// Null when nothing plays.
  double? get musicPosition {
    final music = _music;
    return music != null && music.isPlaying ? music.position : null;
  }

  /// Jumps the music to [seconds] into the loop, keeping the stems together.
  /// Used when the music starts after the run has (unmuting mid-run).
  void seekMusic(double seconds) => _music?.seek(seconds);

  void _playStems({double startAt = 0, Duration fadeIn = Duration.zero}) {
    final fading = fadeIn > Duration.zero;
    final music = _music = _backend.playMusic({
      // The first one is the clock (see [musicPosition])
      for (final name in [
        _song.stems.first,
        ..._song.allStems.where((n) => n != _song.stems.first),
      ])
        if (_stems[name] case final source?)
          name: (
            source,
            RhythmSongs.extraLayers.contains(name) || fading
                ? 0
                : GameConstants.bgmVolume,
          ),
    });
    if (startAt > 0) {
      music.seek(startAt);
    }
    if (fading) {
      // A level's intro: the main stems fade in
      for (final name in _song.stems) {
        music.fade(name, GameConstants.bgmVolume, fadeIn);
      }
    }
  }

  /// Fades the extra backing layers so only [layers] play, and fades the
  /// [muted] main stems out (the others back in)
  void setMusicLayers(List<String> layers, {List<String> muted = const []}) {
    final music = _music;
    if (music == null) {
      return;
    }
    for (final name in _song.allStems) {
      final on = RhythmSongs.extraLayers.contains(name)
          ? layers.contains(name)
          : !muted.contains(name);
      final volume = on ? GameConstants.bgmVolume : 0.0;
      music.fade(name, volume, _layerFade);
    }
  }

  void _stopStems() {
    _music?.stop();
    _music = null;
  }

  /// Plays a rhythm note sample ([timbre] is fire or ice)
  /// pitched to [midi]
  void playNote(
    String timbre,
    int midi, {
    double volume = 1,
    double pan = 0,
  }) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    final source = _notes[timbre];
    if (source == null) {
      return;
    }
    final semitones = midi - _noteBaseMidi[timbre]!;
    _backend.play(
      source,
      volume: GameConstants.soundEffectsVolume * volume,
      pan: pan.clamp(-1.0, 1.0),
      speed: pow(2, semitones / 12).toDouble(),
    );
  }

  /// The midi note the tick sample is tuned to (A5)
  static const _tickBaseMidi = 81;

  /// A short, soft wooden tick pitched to [midi], for turning the level dial
  void playTick(int midi, {double volume = 1}) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _backend.play(
      _tick,
      volume: GameConstants.soundEffectsVolume * volume,
      speed: pow(2, (midi - _tickBaseMidi) / 12).toDouble(),
    );
  }

  void playHeartHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _backend.play(_heartHit, volume: GameConstants.soundEffectsVolume);
  }

  void playOrbHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _backend.play(
      Random().nextBool() ? _orbHit1 : _orbHit2,
      volume: GameConstants.soundEffectsVolume,
    );
  }

  /// The shield caught a heart: a high A, in key with the song
  void playHeartPickupSound() => playNote('ice', 81, volume: 0.8);

  /// The life bar reached a new [stage]: a higher note of A for each one
  void playLifeStageUpSound(int stage) =>
      playNote('ice', const [69, 69, 76, 81, 88][stage], volume: 0.8);

  void playVictorySound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _backend.play(_victory, volume: GameConstants.soundEffectsVolume);
  }

  void playGameOverSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _backend.play(_gameOver, volume: GameConstants.soundEffectsVolume);
  }

  void playMotivationWord(MotivationWordType word) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    final audio = _words[word];
    if (audio == null) {
      return;
    }
    _backend.play(audio, volume: GameConstants.soundEffectsVolume * 1.5);
  }
}
