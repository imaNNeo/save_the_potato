import 'dart:ui';

import 'package:equatable/equatable.dart';

sealed class GameMode with EquatableMixin {
  const GameMode({
    required this.increasesDifficulty,
    required this.canSpawnMovingHealth,
    required this.passedTime,
    required this.defendedOrbsCount,
    required this.collidedOrbsCount,
    required this.defendOrbStreakCount,
    required this.initialDelay,
  });

  final bool increasesDifficulty;
  final bool canSpawnMovingHealth;
  final double passedTime;
  final int defendedOrbsCount;
  final int collidedOrbsCount;
  final int defendOrbStreakCount;
  final double initialDelay;

  GameMode updatePassedTime(double dt) {
    final gameMode = this;
    return switch (gameMode) {
      GameModeSingleSpawn() => gameMode.copyWith(
          passedTime: gameMode.passedTime + dt,
        ),
      GameModeMultiSpawn() => gameMode.copyWith(
          passedTime: gameMode.passedTime + dt,
        ),
    };
  }

  GameMode increaseDefendedOrbsCount({
    required int count,
  }) {
    final gameMode = this;
    return switch (gameMode) {
      GameModeSingleSpawn() => gameMode.copyWith(
          defendedOrbsCount: gameMode.defendedOrbsCount + count,
        ),
      GameModeMultiSpawn() => gameMode.copyWith(
          defendedOrbsCount: gameMode.defendedOrbsCount + count,
        ),
    };
  }

  GameMode increaseCollidedOrbsCount({
    required int count,
  }) {
    final gameMode = this;
    return switch (gameMode) {
      GameModeSingleSpawn() => gameMode.copyWith(
          collidedOrbsCount: gameMode.collidedOrbsCount + count,
        ),
      GameModeMultiSpawn() => gameMode.copyWith(
          collidedOrbsCount: gameMode.collidedOrbsCount + count,
        ),
    };
  }

  GameMode increaseDefendOrbStreakCount({
    required int count,
  }) {
    final gameMode = this;
    return switch (gameMode) {
      GameModeSingleSpawn() => gameMode.copyWith(
          defendOrbStreakCount: gameMode.defendOrbStreakCount + count,
        ),
      GameModeMultiSpawn() => gameMode.copyWith(
          defendOrbStreakCount: gameMode.defendOrbStreakCount + count,
        ),
    };
  }

  GameMode resetDefendOrbStreakCount() {
    final gameMode = this;
    return switch (gameMode) {
      GameModeSingleSpawn() => gameMode.copyWith(
          defendOrbStreakCount: 0,
        ),
      GameModeMultiSpawn() => gameMode.copyWith(
          defendOrbStreakCount: 0,
        ),
    };
  }

  GameMode updateInitialDelay(double delay) {
    final gameMode = this;
    return switch (gameMode) {
      GameModeSingleSpawn() => gameMode.copyWith(
          initialDelay: delay,
        ),
      GameModeMultiSpawn() => gameMode.copyWith(
          initialDelay: delay,
        ),
    };
  }

  @override
  bool? get stringify => true;
}

class GameModeSingleSpawn extends GameMode {
  const GameModeSingleSpawn({
    super.passedTime = 0,
    super.defendedOrbsCount = 0,
    super.collidedOrbsCount = 0,
    super.defendOrbStreakCount = 0,
    super.initialDelay = 0,
  }) : super(
          increasesDifficulty: true,
          canSpawnMovingHealth: true,
        );

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsSpawnEveryInitial] to [orbsSpawnEveryPeak]
  static const orbsSpawnEveryInitial = 2.2;
  static const orbsSpawnEveryPeak = 0.65;

  double getSpawnOrbsEvery(double difficulty) => lerpDouble(
        orbsSpawnEveryInitial,
        orbsSpawnEveryPeak,
        difficulty,
      )!;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsMoveSpeedInitial] to [orbsMoveSpeedPeak]
  static const orbsMoveSpeedInitial = 135.0;
  static const orbsMoveSpeedPeak = 215.0;

  double getSpawnOrbsMoveSpeed(double difficulty) => lerpDouble(
        orbsMoveSpeedInitial,
        orbsMoveSpeedPeak,
        difficulty,
      )!;

  GameModeSingleSpawn copyWith({
    double? passedTime,
    int? defendedOrbsCount,
    int? collidedOrbsCount,
    int? defendOrbStreakCount,
    double? initialDelay,
  }) {
    return GameModeSingleSpawn(
      passedTime: passedTime ?? this.passedTime,
      defendedOrbsCount: defendedOrbsCount ?? this.defendedOrbsCount,
      collidedOrbsCount: collidedOrbsCount ?? this.collidedOrbsCount,
      defendOrbStreakCount: defendOrbStreakCount ?? this.defendOrbStreakCount,
      initialDelay: initialDelay ?? this.initialDelay,
    );
  }

  @override
  List<Object?> get props => [
        passedTime,
        defendedOrbsCount,
        collidedOrbsCount,
        increasesDifficulty,
        canSpawnMovingHealth,
        defendOrbStreakCount,
        initialDelay,
      ];
}

class GameModeMultiSpawn extends GameMode {
  const GameModeMultiSpawn({
    required this.spawnerSpawnCount,
    super.passedTime = 0,
    super.defendedOrbsCount = 0,
    super.collidedOrbsCount = 0,
    super.defendOrbStreakCount = 0,
    super.initialDelay = 0,
  }) : super(
          increasesDifficulty: false,
          canSpawnMovingHealth: false,
        );

  bool shouldPlayMotivationWord() => collidedOrbsCount == 0;

  final int spawnerSpawnCount;

  int orbsSpawnCount() => 6;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsSpawnEveryInitial] to [orbsSpawnEveryPeak]
  static const orbsSpawnEveryInitial = 0.6;
  static const orbsSpawnEveryPeak = 0.2;

  double getSpawnOrbsEvery(double difficulty) => lerpDouble(
        orbsSpawnEveryInitial,
        orbsSpawnEveryPeak,
        difficulty,
      )!;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsMoveSpeedInitial] to [orbsMoveSpeedPeak]
  static const orbsMoveSpeedInitial = 125;
  static const orbsMoveSpeedPeak = 215;

  double getSpawnOrbsMoveSpeed(double difficulty) => lerpDouble(
        orbsMoveSpeedInitial,
        orbsMoveSpeedPeak,
        difficulty,
      )!;

  static const orbsSpawnerSpawnEveryInitial = 5.5;
  static const orbsSpawnerSpawnEveryPeak = 2;

  double getSpawnOrbsSpawnerEvery(double difficulty) => lerpDouble(
        orbsSpawnerSpawnEveryInitial,
        orbsSpawnerSpawnEveryPeak,
        difficulty,
      )!;

  GameModeMultiSpawn copyWith({
    int? spawnerSpawnCount,
    double? passedTime,
    int? defendedOrbsCount,
    int? collidedOrbsCount,
    int? defendOrbStreakCount,
    double? initialDelay,
  }) {
    return GameModeMultiSpawn(
      spawnerSpawnCount: spawnerSpawnCount ?? this.spawnerSpawnCount,
      passedTime: passedTime ?? this.passedTime,
      defendedOrbsCount: defendedOrbsCount ?? this.defendedOrbsCount,
      collidedOrbsCount: collidedOrbsCount ?? this.collidedOrbsCount,
      defendOrbStreakCount: defendOrbStreakCount ?? this.defendOrbStreakCount,
      initialDelay: initialDelay ?? this.initialDelay,
    );
  }

  @override
  List<Object?> get props => [
        spawnerSpawnCount,
        passedTime,
        defendedOrbsCount,
        collidedOrbsCount,
        increasesDifficulty,
        canSpawnMovingHealth,
        defendOrbStreakCount,
        initialDelay,
      ];
}
