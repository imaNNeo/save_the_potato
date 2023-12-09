import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:ice_fire_game/game_configs.dart';
import 'package:ice_fire_game/list_extension.dart';

import '../cubit/game_cubit.dart';
import '../my_game.dart';

class ElementBallSpawner extends PositionComponent with HasGameRef<MyGame> {
  ElementBallSpawner({
    required super.position,
    required this.type,
    required this.spawnInterval,
    required this.spawnCount,
  });

  final double spawnInterval;
  final TemperatureType type;
  final int spawnCount;

  double _timeSinceLastSpawn = 0;
  int spawned = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawn();
    }
    if (spawned >= spawnCount) {
      removeFromParent();
    }
  }

  void _spawn() {
    if (game.playingState != PlayingState.playing) {
      return;
    }
    spawned++;
    const speedMin = 80;
    const speedMax = 150;
    game.world.add(
      ElementBall(
        type: type,
        speed: Random().nextDouble() * (speedMax - speedMin) + speedMin,
        size: 18 + Random().nextDouble() * 4,
        target: game.world.player,
        position: position.clone(),
      ),
    );
  }
}

class ElementBall extends PositionComponent
    with
        HasGameRef<MyGame>,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  ElementBall({
    required this.type,
    required this.speed,
    required double size,
    required this.target,
    required super.position,
  }) : super(size: Vector2.all(size), priority: 1);

  final TemperatureType type;
  final double speed;
  final PositionComponent target;
  late Timer _particleTimer;

  Random get rnd => game.rnd;

  double get radius => size.x / 2;

  List<Color> get colors => switch (type) {
        TemperatureType.hot => game.hotColors,
        TemperatureType.cold => game.coldColors,
      };

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (state.playingState == PlayingState.gameOver) {
      timeScale = GameConfigs.gameOverTimeScale;
    } else {
      timeScale = 1.0;
    }
  }

  @override
  void onLoad() {
    super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));

    _addParticles();
  }

  void _addParticles() {
    _particleTimer = Timer(
      0.04,
      onTick: () {
        final color = colors.random();
        final randomOrder = colors.randomOrder();
        TweenSequence<Color?> colorTween = TweenSequence<Color?>([
          for (int i = 0; i < randomOrder.length - 1; i++)
            TweenSequenceItem(
              weight: 1,
              tween: ColorTween(
                begin: randomOrder[i],
                end: randomOrder[i + 1],
              ),
            ),
        ]);
        game.world.add(ParticleSystemComponent(
          position: positionOfAnchor(Anchor.center),
          anchor: Anchor.center,
          particle: AcceleratedParticle(
            lifespan: 2,
            acceleration: Vector2(
              (rnd.nextDouble() * 200) - (200 / 2),
              (rnd.nextDouble() * 200) - (200 / 2),
            ),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity =
                    Tween(begin: 0.2, end: 0.0).transform(particle.progress);
                // final opacity = 0.2;
                // print(opacity);
                canvas.drawCircle(
                  Offset.zero,
                  (radius * 0.8) * (1 - particle.progress),
                  Paint()
                    ..color = (rnd.nextBool()
                            ? color
                            : colorTween.transform(particle.progress))!
                        .withOpacity(opacity)
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
                );
              },
            ),
          ),
        ));
      },
      repeat: true,
    );
    _particleTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _particleTimer.update(dt);
    final angle = atan2(
      target.position.y - position.y,
      target.position.x - position.x,
    );
    position += Vector2(cos(angle), sin(angle)) * speed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final offset = (size / 2).toOffset();
    final radius = size.x / 2;
    canvas.drawCircle(
      offset,
      radius,
      Paint()
        ..color = type.color.withOpacity(1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      offset,
      radius * 0.8,
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  void onRemove() {
    _particleTimer.stop();
    super.onRemove();
  }

  void dissolve() {
    removeFromParent();
    final color = colors.random();
    final randomOrder = colors.randomOrder();
    TweenSequence<Color?> colorTween = TweenSequence<Color?>([
      for (int i = 0; i < randomOrder.length - 1; i++)
        TweenSequenceItem(
          weight: 1,
          tween: ColorTween(
            begin: randomOrder[i],
            end: randomOrder[i + 1],
          ),
        ),
    ]);
    game.world.add(ParticleSystemComponent(
      position: positionOfAnchor(Anchor.center),
      anchor: Anchor.center,
      particle: Particle.generate(
        count: 20,
        lifespan: 0.8,
        generator: (i) => AcceleratedParticle(
          speed: Vector2(
            (rnd.nextDouble() * 200) - 100,
            (rnd.nextDouble() * 200) - 100,
          ),
          acceleration: Vector2(
            (rnd.nextDouble() * 200) - 100,
            (rnd.nextDouble() * 200) - 100,
          ),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final opacity =
                  Tween(begin: 1.0, end: 0.0).transform(particle.progress);
              canvas.drawCircle(
                Offset.zero,
                (radius * 0.6) * (1 - particle.progress),
                Paint()
                  ..color = (rnd.nextBool()
                          ? color
                          : colorTween.transform(particle.progress))!
                      .withOpacity(opacity)
                  ..maskFilter = MaskFilter.blur(
                    BlurStyle.normal,
                    (1 - particle.progress) * 2,
                  ),
              );
            },
          ),
        ),
      ),
    ));
  }
}
