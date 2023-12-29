import 'package:flame_audio/flame_audio.dart';
import 'package:save_the_potato/domain/game_configs.dart';

class AudioHelper {
  late bool audioEnabled;

  double get bgVolume => audioEnabled ? GameConfigs.bgmVolume : 0;

  void setAudioEnabled(bool enabled) {
    audioEnabled = enabled;
    FlameAudio.bgm.audioPlayer.setVolume(bgVolume);
  }

  void playBackgroundMusic() {
    FlameAudio.bgm.play('bg.mp3', volume: bgVolume);
  }
}
