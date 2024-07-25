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
    this.gameModeHistory = const [],
    this.currentGameMode = const GameModeSingleSpawn(),
    this.upcomingGameMode,
    this.playMotivationWord,
    this.motivationWordsPoolToPlay = MotivationWordType.values,
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

  final List<GameMode> gameModeHistory;

  final GameMode currentGameMode;

  final GameMode? upcomingGameMode;

  final MotivationWordType? playMotivationWord;

  final List<MotivationWordType> motivationWordsPoolToPlay;

  double get difficultyLinear =>
      difficultyTimePassed / GameConstants.difficultyInitialToPeakDuration;

  /// Between 0.0 and 1.0
  double get difficulty => GameConstants.difficultyInitialToPeakCurve.transform(
        min(
          1.0,
          difficultyLinear,
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

  /// It's an index to use when we show [GameColors.starsBackground]
  /// and [GameColors.starsColors]. It works as a difficulty level.
  /// 0 -> When the game starts
  /// 1 -> From the first game mode change (multi spawn)
  /// 2 -> When the difficulty is in maximum
  int get gameDifficultyModeIndex {
    // Danger
    if (difficulty >= 1.0) {
      return 2;
    }

    // Moderate
    if (gameModeHistory.isNotEmpty) {
      return 1;
    }

    // Safe
    return 0;
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
    List<GameMode>? gameModeHistory,
    GameMode? currentGameMode,
    ValueWrapper<GameMode>? upcomingGameMode,
    ValueWrapper<MotivationWordType>? playMotivationWord,
    List<MotivationWordType>? motivationWordsPoolToPlay,
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
        gameModeHistory: gameModeHistory ?? this.gameModeHistory,
        currentGameMode: currentGameMode ?? this.currentGameMode,
        upcomingGameMode: upcomingGameMode != null
            ? upcomingGameMode.value
            : this.upcomingGameMode,
        playMotivationWord: playMotivationWord != null
            ? playMotivationWord.value
            : this.playMotivationWord,
        motivationWordsPoolToPlay:
            motivationWordsPoolToPlay ?? this.motivationWordsPoolToPlay,
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
        gameModeHistory,
        currentGameMode,
        upcomingGameMode,
        playMotivationWord,
        motivationWordsPoolToPlay,
      ];
}
