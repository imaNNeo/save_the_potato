import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/custom_particle.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'health/health_disjoint_particle.dart';
import 'orb/moving_orb_head.dart';
import 'orb/moving_orb_tail_particles.dart';
import 'orb/orb_disjoint_particle.dart';
import 'orb/orb_type.dart';

part 'orb/moving_orb.dart';

part 'health/moving_health.dart';

sealed class MovingComponent extends PositionComponent
    with
        HasGameRef<PotatoGame>,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  MovingComponent() : super(priority: 1);

  late double speed;
  late PositionComponent target;

  void initialize({
    required double speed,
    required PositionComponent target,
    required Vector2 position,
    required double size,
  }) {
    this.speed = speed;
    this.target = target;
    this.size = Vector2.all(size);
    this.position = position;
  }

  Random get rnd => game.rnd;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    timeScale = state.gameOverTimeScale;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (bloc.state.playingState.isGameOver) {
      removeFromParent();
    }
    final angle = atan2(
      target.position.y - position.y,
      target.position.x - position.x,
    );
    position += Vector2(cos(angle), sin(angle)) * speed * dt;
  }
}
