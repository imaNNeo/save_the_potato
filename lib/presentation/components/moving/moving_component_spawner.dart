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
import 'package:save_the_potato/presentation/rhythm/rhythm_hit.dart';

import 'moving_components.dart';
import 'multi_orb_spawner.dart';
import 'orb/orb_type.dart';
import 'portal/orb_portal.dart';

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

  /// Portals still forming, their orb hasn't left yet
  final List<OrbPortal> _formingPortals = [];

  /// Where the last portals were, so the next one forms somewhere else
  final List<double> _recentPortalAngles = [];

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
  }

  /// A random spot around the potato, away from the last few portals. It
  /// stays on screen on phones (the world is at least 600 wide).
  Vector2 _randomPortalPosition() {
    final rnd = Random();
    var angle = rnd.nextDouble() * pi * 2;
    for (var i = 0; i < 10; i++) {
      final farEnough = _recentPortalAngles.every(
        (a) => cos(angle - a) < cos(pi / 3),
      );
      if (farEnough) {
        break;
      }
      angle = rnd.nextDouble() * pi * 2;
    }
    _rememberPortalAngle(angle);
    final distance = 185 + rnd.nextDouble() * 40;
    return Vector2(cos(angle), sin(angle)) * distance;
  }

  void _rememberPortalAngle(double angle) {
    _recentPortalAngles.add(angle);
    if (_recentPortalAngles.length > 2) {
      _recentPortalAngles.removeAt(0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!bloc.state.playingState.isPlaying) {
      return;
    }
    if (parent.rhythm.isActive) {
      // The rhythm director spawns the orbs on the beat
      return;
    }
    final gameMode = bloc.state.currentGameMode;
    _formingPortals.removeWhere((p) => p.isRemoved || p.isOpen);
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
              _formingPortals.isEmpty &&
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

  /// How far from the potato orbs spawn
  double get spawnDistance => (game.size.x / 2) + (game.size.x * 0.05);

  bool get hasMovingHealth => movingHealth != null;

  /// Used by the rhythm director, which picks its own moments for hearts
  bool tryToSpawnHealthPoint() => _tryToSpawnHealthPoint();

  /// Spawns one orb for the rhythm director
  void spawnRhythmOrb({
    required OrbType type,
    required Vector2 position,
    required double speed,
    RhythmHit? rhythmHit,
    int? overrideCollisionSoundNumber,
  }) {
    late MovingOrb orb;
    switch (type) {
      case OrbType.fire:
        orb = _fireOrbPool.get();
      case OrbType.ice:
        orb = _iceOrbPool.get();
    }
    orb.loaded.then((_) {
      orb.initialize(
        speed: speed,
        target: player,
        position: position,
        onDisjointCallback: () => _release(orb),
        onPotatoHitCallback: () => _release(orb),
        overrideCollisionSoundNumber: overrideCollisionSoundNumber,
      );
      orb.rhythmHit = rhythmHit;
    });
    parent.add(orb);
  }

  void _release(MovingOrb orb) {
    switch (orb) {
      case FireOrb():
        _fireOrbPool.release(orb);
      case IceOrb():
        _iceOrbPool.release(orb);
    }
  }

  Vector2 _getRandomSpawnPositionAroundMap() {
    final distance = spawnDistance;
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
    final orbType = OrbType.values.random();
    final position = _randomPortalPosition();
    _addWaveSeries(gameMode, orbType, position);

    if (Random().nextDouble() > 2 / 3) {
      return;
    }
    final oppositeOrbType = switch (orbType) {
      OrbType.fire => OrbType.ice,
      OrbType.ice => OrbType.fire,
    };
    final oppositePosition = position.clone()..negate();
    _rememberPortalAngle(atan2(oppositePosition.y, oppositePosition.x));
    _addWaveSeries(
      gameMode,
      oppositeOrbType,
      oppositePosition,
      isOpposite: true,
    );
  }

  /// An angry portal that sweeps around the potato while it pours a series
  void _addWaveSeries(
    GameModeMultiSpawn gameMode,
    OrbType orbType,
    Vector2 position, {
    bool isOpposite = false,
  }) {
    final difficulty = bloc.state.difficulty;
    final spawner = MultiOrbSpawner(
      position: position,
      portal: _openWavePortal(orbType, position),
      startDelay: _wavePortalFormDuration,
      spawnOrbsEvery: gameMode.getSpawnOrbsEvery(difficulty),
      spawnOrbsMoveSpeed: gameMode.getSpawnOrbsMoveSpeed(difficulty),
      orbType: orbType,
      target: player,
      spawnCount: gameMode.orbsSpawnCount(),
      iceOrbPool: _iceOrbPool,
      fireOrbPool: _fireOrbPool,
      isOpposite: isOpposite,
    );
    parent.add(spawner);
    aliveMultiOrbSpawners.add(spawner);
  }

  /// Which way the wave portals sweep this wave. Both ends of a pair turn
  /// the same way, so they stay opposite.
  double get _waveSweepDirection =>
      multiOrbSpawnerSpawnCounter.isEven ? 1.0 : -1.0;

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
    final move = PortalMove.random(difficulty);
    late OrbPortal portal;
    portal = OrbPortal(
      type: orbType,
      position: _randomPortalPosition(),
      formDuration: move.formDuration,
      travel: move.travel,
      travelTime: move.travelTime,
      onOpen: () {
        portal.close();
        if (game.playingState.isPlaying) {
          _throwOrb(orbType, moveSpeed, portal.position.clone());
        }
      },
    );
    parent.add(portal);
    _formingPortals.add(portal);
  }

  static const _wavePortalFormDuration = 0.7;

  /// An angry portal that stays open while its wave pours out of it
  OrbPortal _openWavePortal(OrbType type, Vector2 position) {
    final portal = OrbPortal(
      type: type,
      position: position,
      formDuration: _wavePortalFormDuration,
      angry: true,
      drift: _waveSweepDirection * 1.1,
      driftWhileOpen: true,
    );
    parent.add(portal);
    return portal;
  }

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
