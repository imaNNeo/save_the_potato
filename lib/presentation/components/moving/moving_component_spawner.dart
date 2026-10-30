import 'dart:math';

import 'package:flame/components.dart' hide ComponentPool;
import 'package:flame/extensions.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'moving_components.dart';
import 'multi_orb_spawner.dart';
import 'orb/orb_type.dart';
import 'thrower/orb_thrower.dart';

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

  /// The two enemies that throw the orbs
  late OrbThrower _fireThrower;
  late OrbThrower _iceThrower;

  OrbThrower _throwerOf(OrbType type) =>
      type.isFire ? _fireThrower : _iceThrower;

  /// Orbs that are still winding up in a thrower's hands
  int _pendingThrows = 0;

  @override
  void onLoad() {
    super.onLoad();
    mounted.then((_) {
      _previousGameState = bloc.state;
    });
    _fireOrbPool = ComponentPool<FireOrb>(
      () => FireOrb(),
      initialSize: 10,
      debugName: 'FireOrbPool',
    );
    _iceOrbPool = ComponentPool<IceOrb>(
      () => IceOrb(),
      initialSize: 10,
      debugName: 'IceOrbPool',
    );
    _movingHealthPool = ComponentPool<MovingHealth>(
      () => MovingHealth(),
      initialSize: 3,
      debugName: 'MovingHealthPool',
    );
    final look = ThrowerLook.current;
    parent.addAll([
      _fireThrower = OrbThrower(
        type: OrbType.fire,
        look: look,
        ringAngle: -pi * 0.75,
      ),
      _iceThrower = OrbThrower(
        type: OrbType.ice,
        look: look,
        ringAngle: pi * 0.25,
      ),
    ]);
  }

  /// A random spot on the throwers' ring, away from both throwers
  double _randomThrowerAngle({double minGap = pi / 3}) {
    final rnd = Random();
    var angle = rnd.nextDouble() * pi * 2;
    for (var i = 0; i < 8; i++) {
      final farEnough = [
        _fireThrower,
        _iceThrower,
      ].every((t) => cos(angle - t.ringAngle) < cos(minGap));
      if (farEnough) {
        break;
      }
      angle = rnd.nextDouble() * pi * 2;
    }
    return angle;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!bloc.state.playingState.isPlaying) {
      return;
    }
    final gameMode = bloc.state.currentGameMode;
    final angry =
        gameMode is GameModeMultiSpawn ||
        bloc.state.upcomingGameMode is GameModeMultiSpawn;
    _fireThrower.angry = angry;
    _iceThrower.angry = angry;
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
          if (aliveSingleMovingOrbs.isEmpty &&
              _pendingThrows == 0 &&
              movingHealth == null) {
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
        onDisjointCallback: () {
          _movingHealthPool.release(movingHealth!);
          movingHealth = null;
        },
        onConsumedCallback: () {
          _movingHealthPool.release(movingHealth!);
          movingHealth = null;
        },
      ),
    );
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
    final difficulty = bloc.state.difficulty;
    final orbType = OrbType.values.random();
    final thrower = _throwerOf(orbType);
    final angle = _randomThrowerAngle();
    thrower.moveTo(angle, duration: _throwerGlideToWave);
    final spawner = MultiOrbSpawner(
      position: Vector2(cos(angle), sin(angle)) * thrower.ringRadius,
      thrower: thrower,
      startDelay: _throwerGlideToWave + 0.1,
      spawnOrbsEvery: gameMode.getSpawnOrbsEvery(difficulty),
      spawnOrbsMoveSpeed: gameMode.getSpawnOrbsMoveSpeed(difficulty),
      orbType: orbType,
      target: player,
      spawnCount: gameMode.orbsSpawnCount(),
      iceOrbPool: _iceOrbPool,
      fireOrbPool: _fireOrbPool,
    );
    parent.add(spawner);
    aliveMultiOrbSpawners.add(spawner);

    if (Random().nextDouble() <= 2 / 3) {
      final oppositeOrbType = switch (orbType) {
        OrbType.fire => OrbType.ice,
        OrbType.ice => OrbType.fire,
      };
      final oppositeThrower = _throwerOf(oppositeOrbType);
      oppositeThrower.moveTo(angle + pi, duration: _throwerGlideToWave);
      final oppositeSpawner = MultiOrbSpawner(
        position:
            Vector2(cos(angle + pi), sin(angle + pi)) * thrower.ringRadius,
        thrower: oppositeThrower,
        startDelay: _throwerGlideToWave + 0.1,
        spawnOrbsEvery: gameMode.getSpawnOrbsEvery(difficulty),
        spawnOrbsMoveSpeed: gameMode.getSpawnOrbsMoveSpeed(difficulty),
        orbType: oppositeOrbType,
        target: player,
        spawnCount: gameMode.orbsSpawnCount(),
        iceOrbPool: _iceOrbPool,
        fireOrbPool: _fireOrbPool,
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
    final difficulty = bloc.state.difficulty;
    final moveSpeed = gameMode.getSpawnOrbsMoveSpeed(difficulty);
    final orbType = OrbType.values.random();
    final thrower = _throwerOf(orbType);
    // The wind-up shrinks with the spawn rate so throws never pile up
    final windUp = gameMode.getSpawnOrbsEvery(difficulty) * 0.35;
    _pendingThrows++;
    thrower.windUpAndThrow(windUp, (releasePosition) {
      _pendingThrows--;
      if (!game.playingState.isPlaying) {
        return;
      }
      _throwOrb(orbType, moveSpeed, releasePosition);
      thrower.moveTo(_randomThrowerAngle(), duration: 0.9);
    });
  }

  static const _throwerGlideToWave = 0.5;

  void _throwOrb(OrbType orbType, double moveSpeed, Vector2 position) {
    late MovingOrb orb;
    switch (orbType) {
      case OrbType.fire:
        orb = _fireOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
            speed: moveSpeed,
            target: player,
            position: position,
            onDisjointCallback: () {
              _fireOrbPool.release(orb as FireOrb);
            },
            onPotatoHitCallback: () {
              _fireOrbPool.release(orb as FireOrb);
            },
          ),
        );
      case OrbType.ice:
        orb = _iceOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
            speed: moveSpeed,
            target: player,
            position: position,
            onDisjointCallback: () {
              _iceOrbPool.release(orb as IceOrb);
            },
            onPotatoHitCallback: () {
              _iceOrbPool.release(orb as IceOrb);
            },
          ),
        );
    }
    parent.add(orb);
    aliveSingleMovingOrbs.add(orb);
  }
}
