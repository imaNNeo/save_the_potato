import 'package:flame_audio/flame_audio.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

  Future<void> initializeCache() async {
    await FlameAudio.audioCache.loadAll([
      'background_120_to_135bpm.wav',
      'Heart1.wav',
      'Heart2.wav',
      'Heart3.wav',
      'Hit1.wav',
      'Hit2.wav',
      'Hit3.wav',
      'Shield1.wav',
      'Shield2.wav',
      'Shield3.wav',
      'Shield4.wav',
      'Shield5.wav',
      'Shield6.wav',
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
      'background_120_to_135bpm.wav',
      volume: GameConstants.bgmVolume,
    );
  }

  void playHeartHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    await FlameAudio.play(
      'Heart2.wav',
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playOrbHitSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    await FlameAudio.play(
      'Hit2.wav',
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playShieldSound(int seed) async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    await FlameAudio.play(
      'Shield${(seed % 6) + 1}.wav',
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playVictorySound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    FlameAudio.play(
      'victory.mp3',
      volume: GameConstants.soundEffectsVolume,
    );
  }

  void playGameOverSound() async {
    if (!(await _audioEnabled.value)) {
      return;
    }
    FlameAudio.play(
      'game_over.wav',
      volume: GameConstants.soundEffectsVolume,
    );
  }
}
