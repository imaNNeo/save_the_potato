import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/custom_particle.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'moving_components.dart';
import 'multi_orb_spawner.dart';
import 'orb/orb_type.dart';

class MovingComponentSpawner extends Component
    with ParentIsA<MyWorld>, FlameBlocListenable<GameCubit, GameState> {
  // We increase [timeSinceLastSingleOrbSpawn] to spawn the single moving orbs
  double timeSinceLastSingleOrbSpawn = 0.0;

  // Keeps a list of alive spawners to check if we are ready to switch to
  // the upcoming game mode. We switch only when everything is cleared
  // to prevent gameMode collision
  List<MovingOrb> aliveSingleMovingOrbs = [];

  // To reduce the delay, we want to spawn the first spawner immediately.
  // After that, we increase the [timeSinceLastMultiOrbSpawnerSpawn] to spawn
  bool multiOrbSpawnerFirstSpawned = false;
  double timeSinceLastMultiOrbSpawnerSpawn = 0.0;
  int multiOrbSpawnerSpawnCounter = 0;

  // Keeps a list of alive spawners to check if we are ready to switch to
  // the upcoming game mode. We switch only when everything is cleared
  // to prevent gameMode collision
  List<MultiOrbSpawner> aliveMultiOrbSpawners = [];

  MovingHealth? movingHealth;

  int _firstTimeHealthGeneratedCount = 0;

  double initialDelayTimeRemaining = 0.0;

  Potato get player => parent.player;

  PotatoGame get game => parent.game;

  late GameState _previousGameState;

  late ComponentPool<FireOrb> _fireOrbPool;
  late ComponentPool<IceOrb> _iceOrbPool;
  late ComponentPool<MovingHealth> _movingHealthPool;
  late ComponentPool<CustomParticle> _trailParticlePool;

  @override
  void onLoad() {
    super.onLoad();
    mounted.then((_) {
      _previousGameState = bloc.state;
    });
    _fireOrbPool = ComponentPool<FireOrb>(
      () => FireOrb(),
      initialSize: 10,
    );
    _iceOrbPool = ComponentPool<IceOrb>(
      () => IceOrb(),
      initialSize: 10,
    );
    _movingHealthPool = ComponentPool<MovingHealth>(
      () => MovingHealth(),
      initialSize: 3,
    );
    _trailParticlePool = ComponentPool<CustomParticle>(
      () => CustomParticle(),
      initialSize: 100,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!bloc.state.playingState.isPlaying) {
      return;
    }
    final gameMode = bloc.state.currentGameMode;
    aliveSingleMovingOrbs.removeWhere((e) => e.isRemoved);
    aliveMultiOrbSpawners.removeWhere((e) => e.isRemoved);

    // Check for initial delay
    if (_previousGameState.currentGameMode.runtimeType !=
        gameMode.runtimeType) {
      initialDelayTimeRemaining = gameMode.initialDelay;
    }
    _previousGameState = bloc.state;
    if (initialDelayTimeRemaining > 0) {
      initialDelayTimeRemaining -= dt;
      return;
    }

    // Try to spawn or switch to the upcoming game mode
    switch (gameMode) {
      case GameModeSingleSpawn():
        if (bloc.state.upcomingGameMode != null) {
          if (aliveSingleMovingOrbs.isEmpty && movingHealth == null) {
            bloc.switchToUpcomingMode();
          }
          return;
        }
        timeSinceLastSingleOrbSpawn += dt;
        final spawnOrbsEvery = gameMode.getSpawnOrbsEvery(
          bloc.state.difficulty,
        );
        if (timeSinceLastSingleOrbSpawn >= spawnOrbsEvery &&
            bloc.state.upcomingGameMode == null &&
            movingHealth == null) {
          if (_tryToSpawnHealthPoint()) {
            return;
          }
          timeSinceLastSingleOrbSpawn = 0.0;
          singleSpawn(gameMode);
        }
      case GameModeMultiSpawn():
        if (bloc.state.upcomingGameMode != null) {
          if (aliveMultiOrbSpawners.isEmpty && movingHealth == null) {
            bloc.switchToUpcomingMode();
          }
          return;
        }
        if (multiOrbSpawnerSpawnCounter >= gameMode.spawnerSpawnCount &&
            bloc.state.upcomingGameMode == null) {
          multiOrbSpawnerSpawnCounter = 0;
          timeSinceLastMultiOrbSpawnerSpawn = 0.0;
          multiOrbSpawnerFirstSpawned = false;
          bloc.multiSpawnModeSpawningFinished();
          return;
        }
        timeSinceLastMultiOrbSpawnerSpawn += dt;
        final spawnOrbSpawnerEvery = gameMode.getSpawnOrbsSpawnerEvery(
          bloc.state.difficulty,
        );
        if ((!multiOrbSpawnerFirstSpawned ||
                timeSinceLastMultiOrbSpawnerSpawn >= spawnOrbSpawnerEvery) &&
            bloc.state.upcomingGameMode == null &&
            movingHealth == null) {
          multiOrbSpawnerFirstSpawned = true;
          timeSinceLastMultiOrbSpawnerSpawn = 0.0;
          multiOrbSpawnerSpawnCounter++;
          spawnOrbSpawner(gameMode);
        }
    }
  }

  Vector2 _getRandomSpawnPositionAroundMap() {
    final distance = (game.size.x / 2) + (game.size.x * 0.05);
    final angle = Random().nextDouble() * pi * 2;
    return Vector2(cos(angle), sin(angle)) * distance;
  }

  bool _shouldSpawnHeart() {
    if (!bloc.state.currentGameMode.canSpawnMovingHealth) {
      return false;
    }
    final missingHP = GameConstants.maxHealthPoints - bloc.state.healthPoints;
    if (missingHP == 0) {
      return false;
    }
    late double generateHealthChance;
    if (bloc.state.firstHealthReceived) {
      generateHealthChance = GameConstants.chanceToSpawnHeart;
    } else {
      if (_firstTimeHealthGeneratedCount <
          GameConstants.spawnHeartForFirstTimeMaxCount) {
        generateHealthChance = GameConstants.chanceToSpawnHeartForFirstTime;
      } else {
        generateHealthChance = GameConstants.chanceToSpawnHeart;
      }
      _firstTimeHealthGeneratedCount++;
    }

    return Random().nextDouble() <= generateHealthChance;
  }

  bool _tryToSpawnHealthPoint() {
    if (!_shouldSpawnHeart()) {
      return false;
    }
    // We can improve it later, it should not be depend on the orb speeds.
    // Or maybe it should?
    final moveSpeed = const GameModeSingleSpawn().getSpawnOrbsMoveSpeed(
      bloc.state.difficulty,
    );
    final healthMoveSpeed =
        (moveSpeed * GameConstants.movingHealthPointSpeedMultiplier).clamp(
      GameConstants.movingHealthMinSpeed,
      GameConstants.movingHealthMaxSpeed,
    );

    movingHealth = _movingHealthPool.get();
    movingHealth!.loaded.then(
      (_) => movingHealth!.initialize(
        speed: healthMoveSpeed,
        target: player,
        size: 28,
        position: _getRandomSpawnPositionAroundMap(),
      ),
    );
    movingHealth!.onDisjointCallback = () {
      _movingHealthPool.release(movingHealth!);
      movingHealth = null;
    };
    parent.add(movingHealth!);
    return true;
  }

  void spawnOrbSpawner(GameModeMultiSpawn gameMode) {
    if (bloc.state.upcomingGameMode != null) {
      return;
    }
    if (!game.playingState.isPlaying) {
      return;
    }
    final position = _getRandomSpawnPositionAroundMap();
    final difficulty = bloc.state.difficulty;
    final orbType = OrbType.values.random();
    final spawner = MultiOrbSpawner(
      position: position,
      spawnOrbsEvery: gameMode.getSpawnOrbsEvery(difficulty),
      spawnOrbsMoveSpeed: gameMode.getSpawnOrbsMoveSpeed(difficulty),
      orbType: orbType,
      target: player,
      spawnCount: gameMode.orbsSpawnCount(),
      iceOrbPool: _iceOrbPool,
      fireOrbPool: _fireOrbPool,
      trailOrbPool: _trailParticlePool,
    );
    parent.add(spawner);
    aliveMultiOrbSpawners.add(spawner);

    if (Random().nextDouble() <= 2 / 3) {
      final oppositePosition = position.clone()..negate();
      final oppositeOrbType = switch (orbType) {
        OrbType.fire => OrbType.ice,
        OrbType.ice => OrbType.fire,
      };
      final oppositeSpawner = MultiOrbSpawner(
        position: oppositePosition,
        spawnOrbsEvery: gameMode.getSpawnOrbsEvery(difficulty),
        spawnOrbsMoveSpeed: gameMode.getSpawnOrbsMoveSpeed(difficulty),
        orbType: oppositeOrbType,
        target: player,
        spawnCount: gameMode.orbsSpawnCount(),
        iceOrbPool: _iceOrbPool,
        fireOrbPool: _fireOrbPool,
        trailOrbPool: _trailParticlePool,
        isOpposite: true,
      );
      parent.add(oppositeSpawner);
      aliveMultiOrbSpawners.add(oppositeSpawner);
    }
  }

  void singleSpawn(GameModeSingleSpawn gameMode) {
    if (bloc.state.upcomingGameMode != null) {
      return;
    }
    if (!game.playingState.isPlaying) {
      return;
    }
    final moveSpeed = gameMode.getSpawnOrbsMoveSpeed(bloc.state.difficulty);
    late MovingOrb orb;
    switch (OrbType.values.random()) {
      case OrbType.fire:
        orb = _fireOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
            speed: moveSpeed,
            target: player,
            position: _getRandomSpawnPositionAroundMap(),
            movingTrailParticlePool: _trailParticlePool,
            onDisjoint: () {
              _fireOrbPool.release(orb as FireOrb);
            },
          ),
        );
        break;
      case OrbType.ice:
        orb = _iceOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
            speed: moveSpeed,
            target: player,
            position: _getRandomSpawnPositionAroundMap(),
            movingTrailParticlePool: _trailParticlePool,
            onDisjoint: () {
              _iceOrbPool.release(orb as IceOrb);
            },
          ),
        );
        break;
    }
    parent.add(orb);
    aliveSingleMovingOrbs.add(orb);
  }
}
