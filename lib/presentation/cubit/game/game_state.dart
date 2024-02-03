part of 'game_cubit.dart';

class GameState extends Equatable {
  const GameState({
    this.heatLevel = 0,
    this.timePassed = 0,
    this.playingState = const PlayingStateNone(),
    this.showGameOverUI = false,
    this.shieldsAngleRotationSpeed = 0,
    this.restartGame = false,
    this.onNewHighScore,
  });

  /// Between [GameConstants.minHeatLevel] and [GameConstants.maxHeatLevel]
  final int heatLevel;

  final double timePassed;

  final PlayingState playingState;

  final bool showGameOverUI;

  final double shieldsAngleRotationSpeed;

  final bool restartGame;

  final OnlineScoreEntity? onNewHighScore;

  /// Between 0.0 and 1.0
  double get difficulty => GameConstants.difficultyInitialToPeakCurve.transform(
        min(
          1.0,
          timePassed / GameConstants.difficultyInitialToPeakDuration,
        ),
      );

  /// Between [GameConstants.orbsSpawnEveryInitial] and [GameConstants.orbsSpawnEveryPeak]
  /// based on [difficulty]
  double get spawnOrbsEvery => lerpDouble(
        GameConstants.orbsSpawnEveryInitial,
        GameConstants.orbsSpawnEveryPeak,
        difficulty,
      )!;

  /// Between [GameConstants.orbsMoveSpeedInitial] and [GameConstants.orbsMoveSpeedPeak]
  /// based on [difficulty]
  DoubleRange get spawnOrbsMoveSpeedRange => DoubleRange.lerp(
        GameConstants.orbsMoveSpeedInitial,
        GameConstants.orbsMoveSpeedPeak,
        difficulty,
      );

  double get gameOverTimeScale {
    if (playingState.isPaused) {
      return 0.0;
    }

    if (playingState.isGameOver) {
      if (showGameOverUI) {
        return 0.0;
      } else {
        return GameConstants.gameOverTimeScale;
      }
    }

    return 1.0;
  }

  GameState copyWith({
    int? heatLevel,
    double? timePassed,
    PlayingState? playingState,
    bool? showGameOverUI,
    double? shieldsAngleRotationSpeed,
    bool? restartGame,
    ValueWrapper<OnlineScoreEntity>? onNewHighScore,
  }) {
    return GameState(
      heatLevel: heatLevel ?? this.heatLevel,
      timePassed: timePassed ?? this.timePassed,
      playingState: playingState ?? this.playingState,
      showGameOverUI: showGameOverUI ?? this.showGameOverUI,
      shieldsAngleRotationSpeed:
          shieldsAngleRotationSpeed ?? this.shieldsAngleRotationSpeed,
      restartGame: restartGame ?? this.restartGame,
      onNewHighScore:
          onNewHighScore != null ? onNewHighScore.value : this.onNewHighScore,
    );
  }

  @override
  List<Object?> get props => [
        heatLevel,
        timePassed,
        playingState,
        showGameOverUI,
        shieldsAngleRotationSpeed,
        restartGame,
        onNewHighScore,
      ];
}

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

enum TemperatureType {
  hot,
  cold;

  Color get baseColor => switch (this) {
        TemperatureType.hot => GameConstants.hotColors.first,
        TemperatureType.cold => GameConstants.coldColors.first,
      };

  List<Color> get colors => switch (this) {
        TemperatureType.hot => GameConstants.hotColors,
        TemperatureType.cold => GameConstants.coldColors,
      };
}
