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

  final bool firstHealthReceived;

  final int shieldHitCounter;

  final List<GameMode> gameModeHistory;

  final GameMode currentGameMode;

  final GameMode? upcomingGameMode;

  final MotivationWordType? playMotivationWord;

  final List<MotivationWordType> motivationWordsPoolToPlay;

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
        firstHealthReceived,
        shieldHitCounter,
        gameModeHistory,
        currentGameMode,
        upcomingGameMode,
        playMotivationWord,
        motivationWordsPoolToPlay,
      ];
}
