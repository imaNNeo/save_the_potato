import 'package:flame_audio/flame_audio.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  Future<void> initializeCache() async {
    await FlameAudio.audioCache.loadAll([
      'background_120_to_160bpm.wav',
      'heart.wav',
      'hit.wav',
      'shield.wav',
      'victory.mp3',
      'game_over.wav',
    ]);
  }
  
  void setAudioEnabled(bool enabled) {
    _audioEnabled.setValue(enabled);
  }

  void pauseBackgroundMusic() {
    if (!FlameAudio.bgm.isPlaying) {
      return;
    }
    FlameAudio.bgm.pause();
    isPaused = true;
  }

  void resumeBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    if (isPaused) {
      FlameAudio.bgm.resume();
    } else {
      playBackgroundMusic();
    }
    isPaused = false;
  }

  void playBackgroundMusic() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    FlameAudio.bgm.play(
      'background_120_to_160bpm.wav',
      volume: GameConstants.bgmVolume,
    );
  }

  void playHeartHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    await FlameAudio.play(
      'heart.wav',
      volume: GameConstants.bgmVolume,
    );
  }

  void playOrbHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    await FlameAudio.play(
      'hit.wav',
      volume: GameConstants.bgmVolume,
    );
  }

  void playShieldSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    await FlameAudio.play(
      'shield.wav',
      volume: GameConstants.bgmVolume,
    );
  }

  void playVictorySound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    FlameAudio.play(
      'victory.mp3',
      volume: GameConstants.bgmVolume,
    );
  }

  void playGameOverSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    FlameAudio.play(
      'game_over.wav',
      volume: GameConstants.bgmVolume,
    );
  }
}
