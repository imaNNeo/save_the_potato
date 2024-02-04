part of 'game_cubit.dart';

class GameState extends Equatable {
  const GameState({
    this.healthPoints = GameConstants.maxHealthPoints,
    this.timePassed = 0,
    this.playingState = const PlayingStateNone(),
    this.showGameOverUI = false,
    this.shieldsAngleRotationSpeed = 0,
    this.restartGame = false,
    this.onNewHighScore,
  });

  final int healthPoints;

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
    int? healthPoints,
    double? timePassed,
    PlayingState? playingState,
    bool? showGameOverUI,
    double? shieldsAngleRotationSpeed,
    bool? restartGame,
    ValueWrapper<OnlineScoreEntity>? onNewHighScore,
  }) {
    return GameState(
      healthPoints: healthPoints ?? this.healthPoints,
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
        healthPoints,
        timePassed,
        playingState,
        showGameOverUI,
        shieldsAngleRotationSpeed,
        restartGame,
        onNewHighScore,
      ];
}

// enum OrbType {
//   red,
//   blue;
//
//   Color get baseColor => switch (this) {
//         OrbType.red => GameConstants.redColors.first,
//         OrbType.blue => GameConstants.blueColors.first,
//       };
//
//   List<Color> get colors => switch (this) {
//         OrbType.red => GameConstants.redColors,
//         OrbType.blue => GameConstants.blueColors,
//       };
// }
