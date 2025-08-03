import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/custom_particle.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'moving_components.dart';
import 'orb/orb_disjoint_particle.dart';

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
  final ComponentPool<CustomParticle> trailOrbPool;
  final ComponentPool<OrbDisjointParticleComponent> orbDisjointComponentPool;
  final ComponentPool<CustomParticle> orbDisjointParticlePool;

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
    required this.trailOrbPool,
    required this.orbDisjointComponentPool,
    required this.orbDisjointParticlePool,
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
        orb = fireOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
            speed: spawnOrbsMoveSpeed,
            target: target,
            position: position,
            movingTrailParticlePool: trailOrbPool,
            onDisjoint: (double contactAngle) {
              final disjointComponent = orbDisjointComponentPool.get();
              orb.add(disjointComponent);
              disjointComponent.loaded.then((_) {
                disjointComponent.burst(
                  orbType: orb.type,
                  colors: orb.colors,
                  smallSparkleSprites: orb.smallSparkleSprites,
                  speedProgress: bloc.state.difficulty,
                  contactAngle: contactAngle,
                  particlePool: orbDisjointParticlePool,
                );
                fireOrbPool.release(orb as FireOrb);
              });
            },
          ),
        );
        orb.overrideCollisionSoundNumber = isOpposite ? -1 : spawnedCount % 6;
      case OrbType.ice:
        orb = iceOrbPool.get();
        orb.loaded.then(
          (_) => orb.initialize(
              speed: spawnOrbsMoveSpeed,
              target: target,
              position: position,
              movingTrailParticlePool: trailOrbPool,
              onDisjoint: (double contactAngle) {
                final disjointComponent = orbDisjointComponentPool.get();
                orb.add(disjointComponent);
                disjointComponent.loaded.then((_) {
                  disjointComponent.burst(
                    orbType: orb.type,
                    colors: orb.colors,
                    smallSparkleSprites: orb.smallSparkleSprites,
                    speedProgress: bloc.state.difficulty,
                    contactAngle: contactAngle,
                    particlePool: orbDisjointParticlePool,
                  );
                  iceOrbPool.release(orb as IceOrb);
                });
              },
            ),
        );
        orb.overrideCollisionSoundNumber = isOpposite ? -1 : spawnedCount % 6;
    }
    aliveMovingOrbs.add(orb);
    parent.add(orb);
    spawnedCount++;
  }
}
