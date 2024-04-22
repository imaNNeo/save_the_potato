import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();
  final soLoud = SoLoud.instance;

  late final AudioSource _bgm;
  late final AudioSource _shield1, _shield2, _shield3, _shield4, _shield5,
      _shield6;
  late final AudioSource _heartHit, _orbHit, _orbHit2;
  late final AudioSource _victory, _gameOver;

  late final List<AudioSource> notes;

  SoundHandle? _bgmHandle;

  Future<void> initialize() async {
    if (soLoud.isInitialized) {
      /// For example, when we re-run the app in the debug mode
      return;
    }
    await soLoud.init();
    const baseAssets = 'assets/audio/';
    _bgm = await soLoud.loadAsset(
      '$baseAssets/background_120_to_135bpm.wav',
    );
    _shield1 = await soLoud.loadAsset('$baseAssets/Shield1.wav');
    _shield2 = await soLoud.loadAsset('$baseAssets/Shield2.wav');
    _shield3 = await soLoud.loadAsset('$baseAssets/Shield3.wav');
    _shield4 = await soLoud.loadAsset('$baseAssets/Shield4.wav');
    _shield5 = await soLoud.loadAsset('$baseAssets/Shield5.wav');
    _shield6 = await soLoud.loadAsset('$baseAssets/Shield6.wav');

    _heartHit = await soLoud.loadAsset('$baseAssets/Heart2.wav');
    _orbHit = await soLoud.loadAsset('$baseAssets/Hit2.wav');
    _orbHit2 = await soLoud.loadAsset('$baseAssets/Hit3.wav');

    _victory = await soLoud.loadAsset('$baseAssets/victory.mp3');
    _gameOver = await soLoud.loadAsset('$baseAssets/game_over.wav');

    notes = await SoLoudTools.createNotes();
  }

  void playBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (_bgmHandle != null) {
      soLoud.stop(_bgmHandle!);
    }
    _bgmHandle = await soLoud.play(
      _bgm,
      volume: GameConstants.bgmVolume,
      looping: true,
      loopingStartAt: const Duration(seconds: 150),
    );
    soLoud.setProtectVoice(_bgmHandle!, true);
  }

  void setAudioEnabled(bool enabled) {
    _audioEnabled.setValue(enabled);
  }

  void pauseBackgroundMusic() {
    if (_bgmHandle == null) {
      return;
    }
    soLoud.setPause(_bgmHandle!, true);
    isPaused = true;
  }

  void resumeBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (isPaused) {
      soLoud.setPause(_bgmHandle!, false);
    } else {
      playBackgroundMusic();
    }
    isPaused = false;
  }

  Future<void> fadeAndStopBackgroundMusic(Duration duration) async {
    if (_bgmHandle == null) {
      return;
    }
    soLoud.fadeVolume(_bgmHandle!, 0, duration);
    await Future.delayed(duration);
    soLoud.stop(_bgmHandle!);
  }

  void playHeartHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    soLoud.play(
      _heartHit,
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playOrbHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    soLoud.play(
      Random().nextBool() ? _orbHit : _orbHit2,
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playShieldSound(int seed) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    final shield = switch(seed % 6) {
      0 => _shield1,
      1 => _shield2,
      2 => _shield3,
      3 => _shield4,
      4 => _shield5,
      5 => _shield6,
      _ => throw Exception('Invalid'),
    };
    soLoud.play(
      shield,
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playVictorySound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    soLoud.play(
      _victory,
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playGameOverSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    soLoud.play(
      _gameOver,
      volume: GameConstants.soundEffectsVolume,
    );
  }
}
