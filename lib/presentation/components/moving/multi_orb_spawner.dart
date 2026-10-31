import 'package:flame/components.dart' hide ComponentPool;
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'moving_components.dart';
import 'portal/orb_portal.dart';

class MultiOrbSpawner extends PositionComponent
    with ParentIsA<MyWorld>, FlameBlocListenable<GameCubit, GameState> {
  final double spawnOrbsEvery;
  final double spawnOrbsMoveSpeed;
  final OrbType orbType;
  final PositionComponent target;
  final int spawnCount;
  final bool isOpposite;
  final ComponentPool<FireOrb> fireOrbPool;
  final ComponentPool<IceOrb> iceOrbPool;

  /// The portal this series pours out of, it closes when the series is done
  final OrbPortal? portal;

  /// Lets the portal form before the first orb
  double startDelay;

  bool firstSpawned = false;
  double timeSinceLastSpawn = 0;

  int spawnedCount = 0;

  List<MovingOrb> aliveMovingOrbs = [];

  MultiOrbSpawner({
    super.position,
    required this.spawnOrbsEvery,
    required this.spawnOrbsMoveSpeed,
    required this.orbType,
    required this.target,
    required this.spawnCount,
    required this.fireOrbPool,
    required this.iceOrbPool,
    this.isOpposite = false,
    this.portal,
    this.startDelay = 0,
  });

  @override
  void update(double dt) {
    super.update(dt);
    if (bloc.state.playingState is! PlayingStatePlaying) {
      return;
    }

    final spawnFinished = spawnedCount >= spawnCount;
    aliveMovingOrbs.removeWhere((e) => e.isRemoved);
    if (spawnFinished) {
      portal?.close();
      if (aliveMovingOrbs.isEmpty) {
        removeFromParent();
      }
      return;
    }
    if (isRemoved) {
      return;
    }
    if (startDelay > 0) {
      startDelay -= dt;
      return;
    }
    if (!firstSpawned) {
      firstSpawned = true;
      spawnOrb(spawnedCount);
      spawnedCount++;
      return;
    }
    timeSinceLastSpawn += dt;
    if (timeSinceLastSpawn >= spawnOrbsEvery) {
      timeSinceLastSpawn = 0;
      spawnOrb(spawnedCount);
      spawnedCount++;
    }
  }

  void spawnOrb(int spawnedCount) {
    portal?.kick();
    late MovingOrb orb;
    switch (orbType) {
      case OrbType.fire:
        orb = fireOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
            speed: spawnOrbsMoveSpeed,
            target: target,
            position: position,
            onDisjointCallback: () {
              fireOrbPool.release(orb as FireOrb);
            },
            onPotatoHitCallback: () {
              fireOrbPool.release(orb as FireOrb);
            },
            overrideCollisionSoundNumber: isOpposite ? -1 : spawnedCount % 6,
          ),
        );
      case OrbType.ice:
        orb = iceOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
            speed: spawnOrbsMoveSpeed,
            target: target,
            position: position,
            onDisjointCallback: () {
              iceOrbPool.release(orb as IceOrb);
            },
            onPotatoHitCallback: () {
              iceOrbPool.release(orb as IceOrb);
            },
            overrideCollisionSoundNumber: isOpposite ? -1 : spawnedCount % 6,
          ),
        );
    }
    aliveMovingOrbs.add(orb);
    parent.add(orb);
  }
}
