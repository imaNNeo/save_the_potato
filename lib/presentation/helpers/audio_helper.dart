import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';
import 'package:save_the_potato/presentation/components/motivation_component.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_songs.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  Future<bool> get audioEnabled => _audioEnabled.value;

  late final SoLoud _soLoud;

  late final AudioSource _heartHit, _orbHit1, _orbHit2;
  late final AudioSource _victory, _gameOver;

  /// One-shot notes pitched with the play speed, and the looping stems of
  /// the song the shield plays the melody over (the infinite song, or the
  /// level's). The extra layers start silent and fade in for the later
  /// stages of the song.
  Song _song = RhythmSongs.song;
  static const _layerFade = Duration(milliseconds: 1500);
  static const _noteBaseMidi = {'fire': 60, 'ice': 72};
  final _notes = <String, AudioSource>{};
  final _stems = <String, AudioSource>{};

  /// The stems of the infinite song stay loaded, a level's are loaded when
  /// it is picked
  final _infiniteStems = <String, AudioSource>{};
  final _stemHandles = <String, SoundHandle>{};
  SoundHandle? _stemGroup;

  /// How many steps [initialize] reports, starting the engine counts as one
  static int get loadSteps =>
      1 +
      5 +
      _noteBaseMidi.length +
      RhythmSongs.song.allStems.length +
      MotivationWordType.values.length;

  /// Starts the audio engine and loads every sound. [onProgress] is called
  /// with how many of the [loadSteps] are done.
  Future<void> initialize({void Function(int done)? onProgress}) async {
    var done = 0;
    void step() => onProgress?.call(++done);

    _soLoud = SoLoud.instance;
    await _soLoud.init();
    // The stems alone take 7 voices
    _soLoud.setMaxActiveVoiceCount(40);
    step();

    const baseAssets = 'assets/audio';
    Future<AudioSource> load(String path) async {
      final source = await _soLoud.loadAsset('$baseAssets/$path');
      step();
      return source;
    }

    // Loaded all at once, on the web every file is a separate download
    final heartHit = load('heart.wav');
    final orbHit1 = load('hit1.wav');
    final orbHit2 = load('hit2.wav');
    final victory = load('victory.mp3');
    final gameOver = load('game_over.wav');
    final notes = {
      for (final name in _noteBaseMidi.keys)
        name: load('rhythm/note_$name.ogg'),
    };
    final stems = {
      for (final name in RhythmSongs.song.allStems)
        name: load('${RhythmSongs.song.assetDir}/stem_$name.ogg'),
    };
    final words = [
      for (var word in MotivationWordType.values)
        load('motivation/${word.assetName}'),
    ];

    // Waits for all of them first, so one failing doesn't leave the
    // others' errors unhandled
    await Future.wait<Object?>([
      heartHit,
      orbHit1,
      orbHit2,
      victory,
      gameOver,
      ...notes.values,
      ...stems.values,
      ...words,
    ]);
    _heartHit = await heartHit;
    _orbHit1 = await orbHit1;
    _orbHit2 = await orbHit2;
    _victory = await victory;
    _gameOver = await gameOver;
    for (final e in notes.entries) {
      _notes[e.key] = await e.value;
    }
    for (final e in stems.entries) {
      _infiniteStems[e.key] = await e.value;
    }
    _stems.addAll(_infiniteStems);
  }

  /// Loads the stems of [song] (once), so the next
  /// [playBackgroundMusic] plays it
  Future<void> useSong(Song song) async {
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
        _stems[name] = await _soLoud.loadAsset(
          'assets/audio/${song.assetDir}/stem_$name.ogg',
        );
      }
    }
    // Free the stems of the level played before
    for (final source in previous.values) {
      if (!_infiniteStems.containsValue(source) &&
          !_stems.containsValue(source)) {
        await _soLoud.disposeSource(source);
      }
    }
  }

  void playBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _stopStems();
    _playStems();
  }

  void setAudioEnabled(bool enabled) {
    _audioEnabled.setValue(enabled);
  }

  void pauseBackgroundMusic() {
    if (_stemGroup == null) {
      return;
    }
    isPaused = true;
    for (var element in _soLoud.activeSounds) {
      for (var element in element.handles) {
        _soLoud.setPause(element, true);
      }
    }
  }

  void resumeBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (isPaused) {
      if (_stemGroup != null) {
        _soLoud.setPause(_stemGroup!, false);
      }
    } else {
      playBackgroundMusic();
    }
    isPaused = false;
  }

  Future<void> fadeAndStopBackgroundMusic(Duration duration) async {
    final stems = _stemHandles.values.toList();
    for (final handle in stems) {
      _soLoud.fadeVolume(handle, 0, duration);
    }
    await Future.delayed(duration);
    _stopStems(only: stems);
  }

  /// Where the music is now, in seconds of the file (it wraps when it loops).
  /// Null when nothing plays.
  double? get musicPosition {
    final handle = _stemHandles[_song.stems.first];
    if (handle == null || !_soLoud.getIsValidVoiceHandle(handle)) {
      return null;
    }
    return _soLoud.getPosition(handle).inMicroseconds / 1e6;
  }

  /// Jumps the music to [seconds] into the loop, keeping the stems together.
  /// Used when the music starts after the run has (unmuting mid-run).
  void seekMusic(double seconds) {
    final group = _stemGroup;
    if (group == null || _stemHandles.isEmpty) {
      return;
    }
    final time = Duration(microseconds: (seconds * 1e6).round());
    _soLoud.setPause(group, true);
    for (final handle in _stemHandles.values) {
      if (_soLoud.getIsValidVoiceHandle(handle)) {
        _soLoud.seek(handle, time);
      }
    }
    _soLoud.setPause(group, false);
  }

  void _playStems() {
    final group = _soLoud.createVoiceGroup();
    for (final name in _song.allStems) {
      final source = _stems[name];
      if (source == null) {
        continue;
      }
      final handle = _soLoud.play(
        source,
        volume: RhythmSongs.extraLayers.contains(name)
            ? 0
            : GameConstants.bgmVolume,
        looping: true,
        paused: true,
      );
      _soLoud.setProtectVoice(handle, true);
      _stemHandles[name] = handle;
    }
    _soLoud.addVoicesToGroup(group, _stemHandles.values.toList());
    _stemGroup = group;
    // Start them all on the same sample
    _soLoud.setPause(group, false);
  }

  /// Fades the extra backing layers so only [layers] play, and fades the
  /// [muted] main stems out (the others back in)
  void setMusicLayers(List<String> layers, {List<String> muted = const []}) {
    for (final name in _song.allStems) {
      final handle = _stemHandles[name];
      if (handle == null || !_soLoud.getIsValidVoiceHandle(handle)) {
        continue;
      }
      final on = RhythmSongs.extraLayers.contains(name)
          ? layers.contains(name)
          : !muted.contains(name);
      final volume = on ? GameConstants.bgmVolume : 0.0;
      _soLoud.fadeVolume(handle, volume, _layerFade);
    }
  }

  void _stopStems({List<SoundHandle>? only}) {
    final handles = only ?? _stemHandles.values.toList();
    for (final handle in handles) {
      _soLoud.stop(handle);
    }
    if (only == null || _stemHandles.values.every(handles.contains)) {
      _stemHandles.clear();
      if (_stemGroup != null) {
        _soLoud.destroyVoiceGroup(_stemGroup!);
        _stemGroup = null;
      }
    }
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
    final handle = _soLoud.play(
      source,
      volume: GameConstants.soundEffectsVolume * volume,
      pan: pan.clamp(-1.0, 1.0),
      paused: true,
    );
    final semitones = midi - _noteBaseMidi[timbre]!;
    _soLoud.setRelativePlaySpeed(handle, pow(2, semitones / 12).toDouble());
    _soLoud.setPause(handle, false);
  }

  void playHeartHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _soLoud.play(_heartHit, volume: GameConstants.soundEffectsVolume);
  }

  void playOrbHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _soLoud.play(
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
    _soLoud.play(_victory, volume: GameConstants.soundEffectsVolume);
  }

  void playGameOverSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _soLoud.play(_gameOver, volume: GameConstants.soundEffectsVolume);
  }

  void playMotivationWord(MotivationWordType word) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    final audio = await _soLoud.loadAsset(
      'assets/audio/motivation/${word.assetName}',
    );
    _soLoud.play(audio, volume: GameConstants.soundEffectsVolume * 1.5);
  }
}
