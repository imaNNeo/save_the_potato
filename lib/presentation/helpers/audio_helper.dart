import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';
import 'package:save_the_potato/presentation/components/motivation_component.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_mode.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  Future<bool> get audioEnabled => _audioEnabled.value;

  late final SoLoud _soLoud;

  late final AudioSource _bgm;
  late final List<AudioSource> shieldNotes;
  late final AudioSource _heartHit, _orbHit1, _orbHit2;
  late final AudioSource _victory, _gameOver;

  SoundHandle? _bgmHandle;

  /// Rhythm prototype: one-shot notes pitched with the play speed, and the
  /// looping 120 BPM stems that are of the melody song
  static const _rhythmStems = ['kick', 'pad', 'hats', 'bass', 'claps'];
  static const _noteBaseMidi = {'fire': 60, 'ice': 72};
  final _notes = <String, AudioSource>{};
  final _stems = <String, AudioSource>{};
  final _stemHandles = <String, SoundHandle>{};
  SoundHandle? _stemGroup;

  Future<void> initialize() async {
    _soLoud = SoLoud.instance;
    await _soLoud.init();
    // The stems alone take 7 voices
    _soLoud.setMaxActiveVoiceCount(40);
    const baseAssets = 'assets/audio';
    _bgm = await _soLoud.loadAsset('$baseAssets/bg_120_140c_bpm.ogg');
    shieldNotes = [];
    for (var i = 1; i <= 6; i++) {
      shieldNotes.add(await _soLoud.loadAsset('$baseAssets/Shield$i.wav'));
    }

    _heartHit = await _soLoud.loadAsset('$baseAssets/heart.wav');
    _orbHit1 = await _soLoud.loadAsset('$baseAssets/hit1.wav');
    _orbHit2 = await _soLoud.loadAsset('$baseAssets/hit2.wav');

    _victory = await _soLoud.loadAsset('$baseAssets/victory.mp3');
    _gameOver = await _soLoud.loadAsset('$baseAssets/game_over.wav');

    for (final name in _noteBaseMidi.keys) {
      _notes[name] = await _soLoud.loadAsset(
        '$baseAssets/rhythm/note_$name.ogg',
      );
    }
    for (final name in _rhythmStems) {
      _stems[name] = await _soLoud.loadAsset(
        '$baseAssets/rhythm/stem_$name.ogg',
      );
    }

    // Motivation words
    for (var word in MotivationWordType.values) {
      await _soLoud.loadAsset('$baseAssets/motivation/${word.assetName}');
    }
  }

  void playBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (_bgmHandle != null) {
      _soLoud.stop(_bgmHandle!);
      _bgmHandle = null;
    }
    _stopStems();
    if (RhythmMode.current.value.usesStems) {
      _playStems();
      return;
    }
    _bgmHandle = _soLoud.play(
      _bgm,
      volume: GameConstants.bgmVolume,
      looping: true,
      loopingStartAt: const Duration(minutes: 3, seconds: 0, milliseconds: 480),
    );
    _soLoud.setProtectVoice(_bgmHandle!, true);
  }

  void setAudioEnabled(bool enabled) {
    _audioEnabled.setValue(enabled);
  }

  void pauseBackgroundMusic() {
    if (_bgmHandle == null && _stemGroup == null) {
      return;
    }
    if (_bgmHandle != null) {
      _soLoud.setPause(_bgmHandle!, true);
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
      if (_bgmHandle != null) {
        _soLoud.setPause(_bgmHandle!, false);
      }
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
    if (_bgmHandle == null) {
      await Future.delayed(duration);
      _stopStems(only: stems);
      return;
    }
    final bgm = _bgmHandle!;
    _soLoud.fadeVolume(bgm, 0, duration);
    await Future.delayed(duration);
    _soLoud.stop(bgm);
    _stopStems(only: stems);
  }

  /// Where the music is now, in seconds of the file (it wraps when it loops).
  /// Null when nothing plays.
  double? get musicPosition {
    final handle = _bgmHandle ?? _stemHandles['kick'];
    if (handle == null || !_soLoud.getIsValidVoiceHandle(handle)) {
      return null;
    }
    return _soLoud.getPosition(handle).inMicroseconds / 1e6;
  }

  bool get isPlayingStems => _stemGroup != null;

  void _playStems() {
    final group = _soLoud.createVoiceGroup();
    for (final name in _rhythmStems) {
      final handle = _soLoud.play(
        _stems[name]!,
        volume: GameConstants.bgmVolume,
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

  void playShieldSound(int seed) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (seed < 0) {
      return;
    }
    final shield = shieldNotes[seed % shieldNotes.length];
    _soLoud.play(shield, volume: GameConstants.soundEffectsVolume);
  }

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
