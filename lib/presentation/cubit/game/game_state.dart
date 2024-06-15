part of 'game_cubit.dart';

class GameState extends Equatable {
  const GameState({
    this.healthPoints = GameConstants.maxHealthPoints,
    this.levelTimePassed = 0,
    this.difficultyTimePassed = 0,
    this.playingState = const PlayingStateNone(),
    this.showGameOverUI = false,
    this.shieldsAngleRotationSpeed = 0,
    this.restartGame = false,
    this.onNewHighScore,
    this.firstHealthReceived = false,
    this.shieldHitCounter = 0,
    this.gameMode = const GameModeSingleSpawn(),
    this.upcomingGameMode,
  });

  final int healthPoints;

  final double levelTimePassed;

  final double difficultyTimePassed;

  final PlayingState playingState;

  final bool showGameOverUI;

  final double shieldsAngleRotationSpeed;

  final bool restartGame;

  final OnlineScoreEntity? onNewHighScore;

  final bool firstHealthReceived;

  final int shieldHitCounter;

  final GameMode gameMode;

  final GameMode? upcomingGameMode;

  /// Between 0.0 and 1.0
  double get difficulty => GameConstants.difficultyInitialToPeakCurve.transform(
        min(
          1.0,
          difficultyTimePassed / GameConstants.difficultyInitialToPeakDuration,
        ),
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
    double? levelTimePassed,
    double? difficultyTimePassed,
    PlayingState? playingState,
    bool? showGameOverUI,
    double? shieldsAngleRotationSpeed,
    bool? restartGame,
    ValueWrapper<OnlineScoreEntity>? onNewHighScore,
    bool? firstHealthReceived,
    int? shieldHitCounter,
    GameMode? gameMode,
    ValueWrapper<GameMode>? upcomingGameMode,
  }) =>
      GameState(
        healthPoints: healthPoints ?? this.healthPoints,
        levelTimePassed: levelTimePassed ?? this.levelTimePassed,
        difficultyTimePassed: difficultyTimePassed ?? this.difficultyTimePassed,
        playingState: playingState ?? this.playingState,
        showGameOverUI: showGameOverUI ?? this.showGameOverUI,
        shieldsAngleRotationSpeed:
            shieldsAngleRotationSpeed ?? this.shieldsAngleRotationSpeed,
        restartGame: restartGame ?? this.restartGame,
        onNewHighScore:
            onNewHighScore != null ? onNewHighScore.value : this.onNewHighScore,
        firstHealthReceived: firstHealthReceived ?? this.firstHealthReceived,
        shieldHitCounter: shieldHitCounter ?? this.shieldHitCounter,
        gameMode: gameMode ?? this.gameMode,
        upcomingGameMode: upcomingGameMode != null
            ? upcomingGameMode.value
            : this.upcomingGameMode,
      );

  @override
  List<Object?> get props => [
        healthPoints,
        levelTimePassed,
        difficultyTimePassed,
        playingState,
        showGameOverUI,
        shieldsAngleRotationSpeed,
        restartGame,
        onNewHighScore,
        firstHealthReceived,
        shieldHitCounter,
        gameMode,
        upcomingGameMode,
      ];
}
