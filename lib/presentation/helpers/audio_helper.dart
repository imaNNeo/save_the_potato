import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';
import 'package:save_the_potato/presentation/components/motivation_component.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  Future<bool> get audioEnabled => _audioEnabled.value;

  late final SoLoud _soLoud;

  late final AudioSource _heartHit, _orbHit1, _orbHit2;
  late final AudioSource _victory, _gameOver;

  /// One-shot notes pitched with the play speed, and the looping 120 BPM
  /// stems of the song the shield plays the melody over
  static const _rhythmStems = ['kick', 'pad', 'hats', 'bass', 'claps'];
  static const _noteBaseMidi = {'fire': 60, 'ice': 72};
  final _notes = <String, AudioSource>{};
  final _stems = <String, AudioSource>{};
  final _stemHandles = <String, SoundHandle>{};
  SoundHandle? _stemGroup;

  Future<void> initialize() async {
    _soLoud = SoLoud.instance;
    await _soLoud.init();
    // The stems alone take 5 voices
    _soLoud.setMaxActiveVoiceCount(40);
    const baseAssets = 'assets/audio';
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
    final handle = _stemHandles['kick'];
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
