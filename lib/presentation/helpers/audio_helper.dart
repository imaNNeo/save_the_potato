import 'package:flame_audio/flame_audio.dart';
import 'package:save_the_potato/domain/game_constants.dart';

class AudioHelper {
  late bool audioEnabled;
  bool isPaused = false;

  void setAudioEnabled(bool enabled) {
    audioEnabled = enabled;
  }

  void pauseBackgroundMusic() {
    if (!FlameAudio.bgm.isPlaying) {
      return;
    }
    FlameAudio.bgm.pause();
    isPaused = true;
  }

  void resumeBackgroundMusic() {
    if (!audioEnabled) {
      return;
    }
    if (isPaused) {
      FlameAudio.bgm.resume();
    } else {
      playBackgroundMusic();
    }
    isPaused = false;
  }

  void playBackgroundMusic() {
    if (!audioEnabled) {
      return;
    }
    FlameAudio.bgm.play(
      'bg.mp3',
      volume: GameConstants.bgmVolume,
    );
  }

  void playVictorySound() {
    if (!audioEnabled) {
      return;
    }
    FlameAudio.play(
      'victory.mp3',
      volume: GameConstants.bgmVolume,
    );
  }
}
