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

  /// How the portals appear, while we pick one (`?pacing=` on web)
  final PortalPacing _pacing = PortalPacing.current;

  /// [PortalPacing.twins]: the one fire and one ice portal waiting to throw
  final Map<OrbType, OrbPortal> _twins = {};

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
          if (_pacing == PortalPacing.twins) {
            // Waits until a portal is ready to throw
            if (_twinsSpawn(gameMode)) {
              timeSinceLastSingleOrbSpawn = 0.0;
            }
            return;
          }
          timeSinceLastSingleOrbSpawn = 0.0;
          singleSpawn(gameMode);
        }
      case GameModeMultiSpawn():
        _closeTwins();
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
    final position = _randomPortalPosition();
    final portal = _openWavePortal(orbType, position);
    final spawner = MultiOrbSpawner(
      position: position,
      portal: portal,
      startDelay: _wavePortalFormDuration,
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
      final oppositePosition = position.clone()..negate();
      _rememberPortalAngle(atan2(oppositePosition.y, oppositePosition.x));
      final oppositeSpawner = MultiOrbSpawner(
        position: oppositePosition,
        portal: _openWavePortal(oppositeOrbType, oppositePosition),
        startDelay: _wavePortalFormDuration,
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
    final spawnEvery = gameMode.getSpawnOrbsEvery(difficulty);
    final formDuration = switch (_pacing) {
      // The next portal is already forming while the last orb flies
      PortalPacing.preview => (spawnEvery * 1.1).clamp(0.7, 2.0),
      // It forms slower early on, so new players see where the orb comes from
      _ => (spawnEvery * 0.5).clamp(0.4, 1.0),
    };
    final drift = _pacing == PortalPacing.drift
        ? (Random().nextBool() ? 1 : -1) * 0.9
        : 0.0;
    late OrbPortal portal;
    portal = OrbPortal(
      type: orbType,
      position: _randomPortalPosition(),
      formDuration: formDuration,
      drift: drift,
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

  /// One fire and one ice portal are always around. On each beat one that is
  /// ready throws, collapses, and forms again somewhere else. Returns false
  /// when neither is ready yet.
  bool _twinsSpawn(GameModeSingleSpawn gameMode) {
    if (!game.playingState.isPlaying) {
      return false;
    }
    final difficulty = bloc.state.difficulty;
    final spawnEvery = gameMode.getSpawnOrbsEvery(difficulty);
    for (final type in OrbType.values) {
      final twin = _twins[type];
      if (twin == null || twin.isRemoved || twin.isClosing) {
        _formTwin(type, spawnEvery);
      }
    }
    final ready = OrbType.values.where((t) => _twins[t]!.isOpen).toList();
    if (ready.isEmpty) {
      return false;
    }
    final type = ready.random();
    final portal = _twins[type]!..close();
    _throwOrb(
      type,
      gameMode.getSpawnOrbsMoveSpeed(difficulty),
      portal.position.clone(),
    );
    _formTwin(type, spawnEvery);
    return true;
  }

  void _formTwin(OrbType type, double spawnEvery) {
    final portal = OrbPortal(
      type: type,
      position: _randomPortalPosition(),
      formDuration: (spawnEvery * 1.2).clamp(0.6, 1.8),
    );
    parent.add(portal);
    _twins[type] = portal;
  }

  void _closeTwins() {
    for (final twin in _twins.values) {
      twin.close();
    }
    _twins.clear();
  }

  static const _wavePortalFormDuration = 0.7;

  /// An angry portal that stays open while its wave pours out of it
  OrbPortal _openWavePortal(OrbType type, Vector2 position) {
    final portal = OrbPortal(
      type: type,
      position: position,
      formDuration: _wavePortalFormDuration,
      angry: true,
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

/// How the portals appear in the calm phase. Candidates while we pick one,
/// the web build reads it from `?pacing=` in the page URL.
enum PortalPacing {
  /// Every orb gets its own portal at a random spot
  popUp,

  /// One fire and one ice portal; each throws, collapses and re-forms
  twins,

  /// Like [popUp], but the portal slides around the potato while forming
  drift,

  /// Like [popUp], but the next portal starts forming a whole beat early
  preview;

  static PortalPacing get current {
    final name = Uri.base.queryParameters['pacing'];
    return PortalPacing.values.firstWhere(
      (pacing) => pacing.name == name,
      orElse: () => PortalPacing.twins,
    );
  }
}
