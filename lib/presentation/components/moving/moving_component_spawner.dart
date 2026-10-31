import 'dart:math';

import 'package:flame/components.dart' hide ComponentPool;
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_hit.dart';

import 'moving_components.dart';
import 'orb/orb_type.dart';

class MovingComponentSpawner extends Component
    with ParentIsA<MyWorld>, FlameBlocListenable<GameCubit, GameState> {
  // Spawns the orbs and hearts; the rhythm director decides when

  MovingHealth? movingHealth;

  int _firstTimeHealthGeneratedCount = 0;

  Potato get player => parent.player;

  PotatoGame get game => parent.game;

  late ComponentPool<FireOrb> _fireOrbPool;
  late ComponentPool<IceOrb> _iceOrbPool;
  late ComponentPool<MovingHealth> _movingHealthPool;

  @override
  void onLoad() {
    super.onLoad();
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
}
