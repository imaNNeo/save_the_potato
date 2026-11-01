import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide ComponentPool;
import 'package:flame/extensions.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_hit.dart';
import 'package:save_the_potato/service_locator.dart';

import '../../potato_game.dart';
import 'health/health_disjoint_particle.dart';
import 'orb/orb_type.dart';
import 'rift/ring_rift.dart';

part 'orb/moving_orb.dart';

part 'health/moving_health.dart';

sealed class MovingComponent extends PositionComponent
    with
        HasGameReference<PotatoGame>,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  MovingComponent() : super(priority: 1);

  late double speed;
  late PositionComponent target;
  final _direction = Vector2.zero();

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
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.gameOverTimeScale != newState.gameOverTimeScale;

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
    _direction.setValues(cos(angle), sin(angle));
    position.addScaled(_direction, speed * dt);
  }
}
