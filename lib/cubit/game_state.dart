part of 'game_cubit.dart';

class GameState extends Equatable {
  const GameState({
    this.heatLevel = 0,
    this.timePassed = 0,
    this.playingState = PlayingState.none,
    this.showGameOverUI = false,
  });

  /// Between [GameConfigs.minHeatLevel] and [GameConfigs.maxHeatLevel]
  final int heatLevel;

  final double timePassed;

  final PlayingState playingState;

  final bool showGameOverUI;

  double get spawnOrbsEvery {
    return max(
      GameConfigs.spawnOrbsEveryMinimum,
      GameConfigs.initialSpawnOrbsEvery - (timePassed * 0.015),
    );
  }

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
  }) {
    return GameState(
      heatLevel: heatLevel ?? this.heatLevel,
      timePassed: timePassed ?? this.timePassed,
      playingState: playingState ?? this.playingState,
      showGameOverUI: showGameOverUI ?? this.showGameOverUI,
    );
  }

  @override
  List<Object?> get props => [
        heatLevel,
        timePassed,
        playingState,
        showGameOverUI,
      ];
}

enum PlayingState {
  none,
  playing,
  paused,
  gameOver;

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
