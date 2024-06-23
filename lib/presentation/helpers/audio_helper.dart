import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  Future<bool> get audioEnabled => _audioEnabled.value;

  late final SoLoud _soLoud;

  late final AudioSource _bgm;
  late final AudioSource _shield1,
      _shield2,
      _shield3,
      _shield4,
      _shield5,
      _shield6;
  late final AudioSource _heartHit, _orbHit1, _orbHit2;
  late final AudioSource _victory, _gameOver;

  late final List<AudioSource> notes;

  SoundHandle? _bgmHandle;

  Future<void> initialize() async {
    _soLoud = SoLoud.instance;
    if (await _soLoud.initialized) {
      /// For example, when we re-run the app in the debug mode
      return;
    }
    await _soLoud.init();
    const baseAssets = 'assets/audio';
    _bgm = await _soLoud.loadAsset('$baseAssets/bg_120_140c_bpm.ogg');
    _shield1 = await _soLoud.loadAsset('$baseAssets/Shield1.wav');
    _shield2 = await _soLoud.loadAsset('$baseAssets/Shield2.wav');
    _shield3 = await _soLoud.loadAsset('$baseAssets/Shield3.wav');
    _shield4 = await _soLoud.loadAsset('$baseAssets/Shield4.wav');
    _shield5 = await _soLoud.loadAsset('$baseAssets/Shield5.wav');
    _shield6 = await _soLoud.loadAsset('$baseAssets/Shield6.wav');

    _heartHit = await _soLoud.loadAsset('$baseAssets/heart.wav');
    _orbHit1 = await _soLoud.loadAsset('$baseAssets/hit1.wav');
    _orbHit2 = await _soLoud.loadAsset('$baseAssets/hit2.wav');

    _victory = await _soLoud.loadAsset('$baseAssets/victory.mp3');
    _gameOver = await _soLoud.loadAsset('$baseAssets/game_over.wav');

    notes = await SoLoudTools.createNotes();
  }

  void playBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (_bgmHandle != null) {
      _soLoud.stop(_bgmHandle!);
    }
    _bgmHandle = await _soLoud.play(
      _bgm,
      volume: GameConstants.bgmVolume,
      looping: true,
      loopingStartAt: const Duration(
        minutes: 3,
        seconds: 0,
        milliseconds: 480,
      ),
    );
    _soLoud.setProtectVoice(_bgmHandle!, true);
  }

  void setAudioEnabled(bool enabled) {
    _audioEnabled.setValue(enabled);
  }

  void pauseBackgroundMusic() {
    if (_bgmHandle == null) {
      return;
    }
    _soLoud.setPause(_bgmHandle!, true);
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
      _soLoud.setPause(_bgmHandle!, false);
    } else {
      playBackgroundMusic();
    }
    isPaused = false;
  }

  Future<void> fadeAndStopBackgroundMusic(Duration duration) async {
    if (_bgmHandle == null) {
      return;
    }
    _soLoud.fadeVolume(_bgmHandle!, 0, duration);
    await Future.delayed(duration);
    _soLoud.stop(_bgmHandle!);
  }

  void playHeartHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _soLoud.play(
      _heartHit,
      volume: GameConstants.soundEffectsVolume,
    );
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
    final shield = switch (seed % 6) {
      0 => _shield1,
      1 => _shield2,
      2 => _shield3,
      3 => _shield4,
      4 => _shield5,
      5 => _shield6,
      _ => throw Exception('Invalid'),
    };
    _soLoud.play(
      shield,
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playVictorySound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _soLoud.play(
      _victory,
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playGameOverSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    _soLoud.play(
      _gameOver,
      volume: GameConstants.soundEffectsVolume,
    );
  }
}
