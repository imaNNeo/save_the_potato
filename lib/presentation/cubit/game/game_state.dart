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
    this.heartCharge = 0,
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

  /// Orbs blocked in a row towards the next heart, see
  /// [GameConstants.blocksToEarnHeart]. It only fills while a heart is
  /// missing, and getting hit empties it.
  final int heartCharge;

  final int shieldHitCounter;

  final List<GameMode> gameModeHistory;

  final GameMode currentGameMode;

  final GameMode? upcomingGameMode;

  final MotivationWordType? playMotivationWord;

  final List<MotivationWordType> motivationWordsPoolToPlay;

  /// Between 0.0 and 1.0, before applying the difficulty curve
  double get difficultyLinear => min(
    1.0,
    difficultyTimePassed / GameConstants.difficultyInitialToPeakDuration,
  );

  /// Between 0.0 and 1.0
  double get difficulty =>
      GameConstants.difficultyInitialToPeakCurve.transform(difficultyLinear);

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
    int? heartCharge,
    int? shieldHitCounter,
    List<GameMode>? gameModeHistory,
    GameMode? currentGameMode,
    ValueWrapper<GameMode>? upcomingGameMode,
    ValueWrapper<MotivationWordType>? playMotivationWord,
    List<MotivationWordType>? motivationWordsPoolToPlay,
  }) => GameState(
    healthPoints: healthPoints ?? this.healthPoints,
    levelTimePassed: levelTimePassed ?? this.levelTimePassed,
    difficultyTimePassed: difficultyTimePassed ?? this.difficultyTimePassed,
    playingState: playingState ?? this.playingState,
    showGameOverUI: showGameOverUI ?? this.showGameOverUI,
    shieldsAngleRotationSpeed:
        shieldsAngleRotationSpeed ?? this.shieldsAngleRotationSpeed,
    restartGame: restartGame ?? this.restartGame,
    onNewHighScore: onNewHighScore != null
        ? onNewHighScore.value
        : this.onNewHighScore,
    heartCharge: heartCharge ?? this.heartCharge,
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
    heartCharge,
    shieldHitCounter,
    gameModeHistory,
    currentGameMode,
    upcomingGameMode,
    playMotivationWord,
    motivationWordsPoolToPlay,
  ];
}
