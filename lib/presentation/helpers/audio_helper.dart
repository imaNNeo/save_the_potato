import 'package:flame_audio/flame_audio.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/lazy_value.dart';

class AudioHelper {
  bool isPaused = false;

  final _audioEnabled = LazyValue<bool>();

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
      'bg.mp3',
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
}
