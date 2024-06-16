import 'dart:ui';

import 'package:equatable/equatable.dart';

sealed class GameMode with EquatableMixin {
  const GameMode({
    required this.increasesDifficulty,
    required this.canSpawnMovingHealth,
  });

  final bool increasesDifficulty;
  final bool canSpawnMovingHealth;
}

class GameModeSingleSpawn extends GameMode {
  const GameModeSingleSpawn()
      : super(
          increasesDifficulty: true,
          canSpawnMovingHealth: true,
        );

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsSpawnEveryInitial] to [orbsSpawnEveryPeak]
  static const orbsSpawnEveryInitial = 2;
  static const orbsSpawnEveryPeak = 1.2;

  double getSpawnOrbsEvery(double difficulty) => lerpDouble(
        orbsSpawnEveryInitial,
        orbsSpawnEveryPeak,
        difficulty,
      )!;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsMoveSpeedInitial] to [orbsMoveSpeedPeak]
  static const orbsMoveSpeedInitial = 120.0;
  static const orbsMoveSpeedPeak = 215.0;

  double getSpawnOrbsMoveSpeed(double difficulty) => lerpDouble(
        orbsMoveSpeedInitial,
        orbsMoveSpeedPeak,
        difficulty,
      )!;

  @override
  List<Object?> get props => [
        increasesDifficulty,
      ];
}

class GameModeMultiSpawn extends GameMode {
  const GameModeMultiSpawn({
    required this.spawnerSpawnCount,
  }) : super(
          increasesDifficulty: false,
          canSpawnMovingHealth: false,
        );

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

  @override
  List<Object?> get props => [
        spawnerSpawnCount,
        increasesDifficulty,
      ];
}
