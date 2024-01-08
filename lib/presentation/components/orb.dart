import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import '../my_game.dart';

class Orb extends PositionComponent
    with
        HasGameRef<MyGame>,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  Orb({
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
        TemperatureType.hot => GameConstants.hotColors,
        TemperatureType.cold => GameConstants.coldColors,
      };

  List<Sprite> _sparkleSprites = [];
  List<Sprite> _snowflakeSprites = [];

  late Paint particlePaint;
  late Paint headPaint;
  late Paint disjointParticlePaint;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    timeScale = state.gameOverTimeScale;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _sparkleSprites = [];
    for (int i = 1; i <= 2; i++) {
      _sparkleSprites.add(await Sprite.load('sparkle/sparkle$i.png'));
    }

    _snowflakeSprites = [];
    for (int i = 1; i <= 2; i++) {
      _snowflakeSprites.add(await Sprite.load('snow/snowflake$i.png'));
    }

    particlePaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    headPaint = Paint();
    disjointParticlePaint = Paint();
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
        final sprite = switch (type) {
          TemperatureType.hot => _sparkleSprites.random(),
          TemperatureType.cold => _snowflakeSprites.random(),
        };
        game.world.add(ParticleSystemComponent(
          position: positionOfAnchor(Anchor.center),
          anchor: Anchor.center,
          particle: Particle.generate(
            lifespan: 1.2,
            count: 2,
            generator: (index) => AcceleratedParticle(
              acceleration: Vector2(
                (rnd.nextDouble() * 200) - (200 / 2),
                (rnd.nextDouble() * 200) - (200 / 2),
              ),
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final opacity = Tween(begin: 0.8, end: 0.0)
                      .chain(CurveTween(curve: Curves.easeOutQuart))
                      .transform(particle.progress);
                  canvas.rotate(particle.progress * pi * 2);
                  sprite.render(
                    canvas,
                    size: Vector2.all((size.x * 0.7) * (1 - particle.progress)),
                    anchor: Anchor.center,
                    overridePaint: particlePaint
                      ..colorFilter = ColorFilter.mode(
                        (rnd.nextBool()
                                ? color
                                : colorTween.transform(particle.progress))!
                            .withOpacity(opacity),
                        BlendMode.srcIn,
                      ),
                  );
                },
              ),
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
    if (bloc.state.playingState.isGameOver) {
      removeFromParent();
    }
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
      radius * 1.4,
      headPaint
        ..color = type.colors.last.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    canvas.drawCircle(
      offset,
      radius,
      headPaint
        ..color = type.colors.last.withOpacity(1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    canvas.drawCircle(
      offset,
      radius,
      headPaint
        ..color = type.colors.last.withOpacity(1)
        ..maskFilter = null,
    );
    canvas.drawCircle(
      offset,
      radius * 0.75,
      headPaint
        ..color = Colors.white.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  void onRemove() {
    _particleTimer.stop();
    super.onRemove();
  }

  void disjoint() {
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
        count: 30,
        lifespan: 2,
        generator: (i) {
          final sprite = switch (type) {
            TemperatureType.hot => _sparkleSprites.random(),
            TemperatureType.cold => _snowflakeSprites.random(),
          };
          return AcceleratedParticle(
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
                final opacity = Tween(begin: 0.8, end: 0.0)
                    .chain(CurveTween(curve: Curves.easeOutCubic))
                    .transform(particle.progress);
                if (opacity <= 0.01) {
                  return;
                }
                if (i % 3 == 0) {
                  canvas.drawCircle(
                    Offset.zero,
                    (radius * 0.6) * (1 - particle.progress),
                    disjointParticlePaint
                      ..colorFilter = null
                      ..maskFilter = null
                      ..color = (rnd.nextBool()
                              ? color
                              : colorTween.transform(particle.progress))!
                          .withOpacity(opacity),
                  );
                } else {
                  sprite.render(
                    canvas,
                    size: Vector2.all((size.x * 1.2) * (1 - particle.progress)),
                    anchor: Anchor.center,
                    overridePaint: disjointParticlePaint
                      ..colorFilter = ColorFilter.mode(
                        (rnd.nextBool()
                                ? color
                                : colorTween.transform(particle.progress))!
                            .withOpacity(opacity),
                        BlendMode.srcIn,
                      )
                      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
                  );
                }
              },
            ),
          );
        },
      ),
    ));
  }
}
