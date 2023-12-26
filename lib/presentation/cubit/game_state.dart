part of 'game_cubit.dart';

class GameState extends Equatable {
  const GameState({
    this.heatLevel = 0,
    this.timePassed = 0,
    this.playingState = PlayingState.none,
    this.showGameOverUI = false,
    this.shieldsAngleRotationSpeed = 0,
  });

  /// Between [GameConfigs.minHeatLevel] and [GameConfigs.maxHeatLevel]
  final int heatLevel;

  final double timePassed;

  final PlayingState playingState;

  final bool showGameOverUI;

  final double shieldsAngleRotationSpeed;

  /// Between 0.0 and 1.0
  double get difficulty => Curves.easeOutCubic.transform(min(
        1.0,
        timePassed / GameConfigs.difficultyInitialToPeakDuration,
      ));

  /// Between [GameConfigs.orbsSpawnEveryInitial] and [GameConfigs.orbsSpawnEveryPeak]
  /// based on [difficulty]
  double get spawnOrbsEvery => lerpDouble(
        GameConfigs.orbsSpawnEveryInitial,
        GameConfigs.orbsSpawnEveryPeak,
        difficulty,
      )!;

  /// Between [GameConfigs.orbsMoveSpeedInitial] and [GameConfigs.orbsMoveSpeedPeak]
  /// based on [difficulty]
  DoubleRange get spawnOrbsMoveSpeedRange => DoubleRange.lerp(
        GameConfigs.orbsMoveSpeedInitial,
        GameConfigs.orbsMoveSpeedPeak,
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
        return GameConfigs.gameOverTimeScale;
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
  }) {
    return GameState(
      heatLevel: heatLevel ?? this.heatLevel,
      timePassed: timePassed ?? this.timePassed,
      playingState: playingState ?? this.playingState,
      showGameOverUI: showGameOverUI ?? this.showGameOverUI,
      shieldsAngleRotationSpeed:
          shieldsAngleRotationSpeed ?? this.shieldsAngleRotationSpeed,
    );
  }

  @override
  List<Object?> get props => [
        heatLevel,
        timePassed,
        playingState,
        showGameOverUI,
        shieldsAngleRotationSpeed,
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
        TemperatureType.hot => GameConfigs.hotColors.first,
        TemperatureType.cold => GameConfigs.coldColors.first,
      };

  List<Color> get colors => switch (this) {
        TemperatureType.hot => GameConfigs.hotColors,
        TemperatureType.cold => GameConfigs.coldColors,
      };
}
