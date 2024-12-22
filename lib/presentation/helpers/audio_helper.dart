import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';
import 'package:save_the_potato/presentation/components/motivation_component.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  static const _baseAssets = 'assets/audio';

  Future<bool> get audioEnabled => _audioEnabled.value;

  late final SoLoud _soLoud;

  late final AudioSource _bgm;
  late final List<AudioSource> shieldNotes;
  late final AudioSource _heartHit, _orbHit1, _orbHit2;
  late final AudioSource _gameOver;

  SoundHandle? _bgmHandle;

  Future<void> initialize() async {
    _soLoud = SoLoud.instance;
    if (await _soLoud.initialized) {
      /// For example, when we re-run the app in the debug mode
      return;
    }
    await _soLoud.init();
    _bgm = await _soLoud.loadAsset('$_baseAssets/bg_120_140c_bpm.ogg');
  }

  Future<void> loadGameAssets() async {
    shieldNotes = [];
    for (var i = 1; i <= 6; i++) {
      shieldNotes.add(await _soLoud.loadAsset('$_baseAssets/Shield$i.ogg'));
    }

    _orbHit1 = await _soLoud.loadAsset('$_baseAssets/hit1.ogg');
    _orbHit2 = await _soLoud.loadAsset('$_baseAssets/hit2.ogg');

    _heartHit = await _soLoud.loadAsset('$_baseAssets/heart.ogg');

    _gameOver = await _soLoud.loadAsset('$_baseAssets/game_over.ogg');

    // Motivation words
    for (var word in MotivationWordType.values) {
      await _soLoud.loadAsset('$_baseAssets/motivation/${word.assetName}');
    }
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
    final shield = shieldNotes[seed % shieldNotes.length];
    _soLoud.play(
      shield,
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

  void playMotivationWord(MotivationWordType word) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    final audio = await _soLoud.loadAsset(
      'assets/audio/motivation/${word.assetName}',
    );
    _soLoud.play(
      audio,
      volume: GameConstants.soundEffectsVolume * 1.5,
    );
  }
}
