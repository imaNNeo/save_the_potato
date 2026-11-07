part of 'game_cubit.dart';

class GameState extends Equatable {
  const GameState({
    this.life = LifeMeter.start,
    this.levelTimePassed = 0,
    this.difficultyTimePassed = 0,
    this.playingState = const PlayingStateNone(),
    this.showGameOverUI = false,
    this.shieldsTurnDirection = 0,
    this.restartGame = false,
    this.onNewHighScore,
    this.firstHealthReceived = false,
    this.shieldHitCounter = 0,
    this.gameModeHistory = const [],
    this.currentGameMode = const GameModeSingleSpawn(),
    this.upcomingGameMode,
    this.playMotivationWord,
    this.motivationWordsPoolToPlay = MotivationWordType.values,
    this.level,
    this.levelsCleared = 0,
    this.tutorial = false,
    this.tutorialHint = 0,
  });

  /// The level picked on the home screen, null for the infinite mode
  final int? level;

  /// How many levels are cleared, so the next one is open
  final int levelsCleared;

  bool get isLevelsMode => level != null;

  /// The song of this run
  Song get song => level == null ? RhythmSongs.song : Levels.songOf(level!);

  /// True while a first-time player is in the tutorial playground: the
  /// run is "playing" (shields turn, orbs fly) but time, score and life
  /// stand still, see [GameCubit.finishTutorial]
  final bool tutorial;

  /// Which turn button the tutorial points at: -1 left, 1 right, 0 none
  final int tutorialHint;

  /// From 0 to 1, see [LifeMeter]
  final double life;

  int get lifeStage => LifeMeter.stageOf(life);

  final double levelTimePassed;

  final double difficultyTimePassed;

  final PlayingState playingState;

  final bool showGameOverUI;

  final int shieldsTurnDirection;

  final bool restartGame;

  final OnlineScoreEntity? onNewHighScore;

  final bool firstHealthReceived;

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
  double get difficulty {
    final level = this.level;
    if (level != null) {
      // A level ramps up over its song, see [Levels.difficultyAt]
      final progress = difficultyTimePassed / song.durationSeconds!;
      return Levels.difficultyAt(level, progress);
    }
    return GameConstants.difficultyInitialToPeakCurve.transform(
      difficultyLinear,
    );
  }

  /// Between 0.0 and 1.0: how far past the peak the game is, see
  /// [GameConstants.overdriveDuration]. 0 until [difficulty] reaches 1.
  double get overdrive => min(
    1.0,
    max(
      0.0,
      (difficultyTimePassed - GameConstants.difficultyInitialToPeakDuration) /
          GameConstants.overdriveDuration,
    ),
  );

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
    double? life,
    double? levelTimePassed,
    double? difficultyTimePassed,
    PlayingState? playingState,
    bool? showGameOverUI,
    int? shieldsTurnDirection,
    bool? restartGame,
    ValueWrapper<OnlineScoreEntity>? onNewHighScore,
    bool? firstHealthReceived,
    int? shieldHitCounter,
    List<GameMode>? gameModeHistory,
    GameMode? currentGameMode,
    ValueWrapper<GameMode>? upcomingGameMode,
    ValueWrapper<MotivationWordType>? playMotivationWord,
    List<MotivationWordType>? motivationWordsPoolToPlay,
    ValueWrapper<int>? level,
    int? levelsCleared,
    bool? tutorial,
    int? tutorialHint,
  }) => GameState(
    life: life ?? this.life,
    levelTimePassed: levelTimePassed ?? this.levelTimePassed,
    difficultyTimePassed: difficultyTimePassed ?? this.difficultyTimePassed,
    playingState: playingState ?? this.playingState,
    showGameOverUI: showGameOverUI ?? this.showGameOverUI,
    shieldsTurnDirection: shieldsTurnDirection ?? this.shieldsTurnDirection,
    restartGame: restartGame ?? this.restartGame,
    onNewHighScore: onNewHighScore != null
        ? onNewHighScore.value
        : this.onNewHighScore,
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
    level: level != null ? level.value : this.level,
    levelsCleared: levelsCleared ?? this.levelsCleared,
    tutorial: tutorial ?? this.tutorial,
    tutorialHint: tutorialHint ?? this.tutorialHint,
  );

  @override
  List<Object?> get props => [
    life,
    levelTimePassed,
    difficultyTimePassed,
    playingState,
    showGameOverUI,
    shieldsTurnDirection,
    restartGame,
    onNewHighScore,
    firstHealthReceived,
    shieldHitCounter,
    gameModeHistory,
    currentGameMode,
    upcomingGameMode,
    playMotivationWord,
    motivationWordsPoolToPlay,
    level,
    levelsCleared,
    tutorial,
    tutorialHint,
  ];
}
