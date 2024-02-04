part of 'game_cubit.dart';

sealed class PlayingState {
  const PlayingState();

  bool get isGuide => this is PlayingStateGuide;

  bool get isNone => this is PlayingStateNone;

  bool get isGameOver => this is PlayingStateGameOver;

  bool get isPlaying => this is PlayingStatePlaying;

  bool get isPaused => this is PlayingStatePaused;
}

class PlayingStateNone extends PlayingState {
  const PlayingStateNone();
}

class PlayingStateGuide extends PlayingState {
  const PlayingStateGuide();
}

class PlayingStatePlaying extends PlayingState {
  const PlayingStatePlaying();
}

class PlayingStatePaused extends PlayingState {
  const PlayingStatePaused();
}

class PlayingStateGameOver extends PlayingState {
  final int score;
  final bool isHighScore;

  const PlayingStateGameOver({
    required this.score,
    required this.isHighScore,
  });
}