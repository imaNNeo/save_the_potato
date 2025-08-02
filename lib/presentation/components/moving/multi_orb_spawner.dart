import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'moving_components.dart';

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
      if (aliveMovingOrbs.isEmpty) {
        removeFromParent();
      }
      return;
    }
    if (isRemoved) {
      return;
    }
    if (!firstSpawned) {
      firstSpawned = true;
      spawnOrb();
      return;
    }
    timeSinceLastSpawn += dt;
    if (timeSinceLastSpawn >= spawnOrbsEvery) {
      timeSinceLastSpawn = 0;
      spawnOrb();
    }
  }

  void spawnOrb() {
    late MovingOrb orb;
    switch (orbType) {
      case OrbType.fire:
        orb = fireOrbPool.get()
          ..initialize(
            speed: spawnOrbsMoveSpeed,
            target: target,
            position: position,
          );
        orb.overrideCollisionSoundNumber =
            isOpposite ? -1 : spawnedCount % 6;
        orb.onDisjointCallback = () {
          fireOrbPool.release(orb as FireOrb);
        };
      case OrbType.ice:
        orb = iceOrbPool.get()
          ..initialize(
            speed: spawnOrbsMoveSpeed,
            target: target,
            position: position,
          );
        orb.overrideCollisionSoundNumber =
            isOpposite ? -1 : spawnedCount % 6;
        orb.onDisjointCallback = () {
          iceOrbPool.release(orb as IceOrb);
        };
    }
    aliveMovingOrbs.add(orb);
    parent.add(orb);
    spawnedCount++;
  }
}
