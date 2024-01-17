part of 'game_cubit.dart';

class GameState extends Equatable {
  const GameState({
    this.heatLevel = 0,
    this.timePassed = 0,
    this.playingState = PlayingState.none,
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
  double get difficulty => Curves.easeOutCubic.transform(min(
        1.0,
        timePassed / GameConstants.difficultyInitialToPeakDuration,
      ));

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

enum PlayingState {
  none,
  guide,
  playing,
  paused,
  gameOver;

  bool get isGuide => this == PlayingState.guide;

  bool get isNone => this == PlayingState.none;

  bool get isGameOver => this == PlayingState.gameOver;

  bool get isPlaying => this == PlayingState.playing;

  bool get isPaused => this == PlayingState.paused;
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
