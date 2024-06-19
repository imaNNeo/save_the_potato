import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/service_locator.dart';

import '../../my_game.dart';
import 'health/health_disjoint_particle.dart';
import 'orb/moving_orb_head.dart';
import 'orb/moving_orb_tail_particles.dart';
import 'orb/orb_disjoint_particle.dart';
import 'orb/orb_type.dart';

part 'orb/moving_orb.dart';

part 'health/moving_health.dart';

sealed class MovingComponent extends PositionComponent
    with
        HasGameRef<MyGame>,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  MovingComponent({
    required this.speed,
    required double size,
    required this.target,
    required super.position,
  }) : super(size: Vector2.all(size), priority: 1);

  final double speed;
  final PositionComponent target;

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
