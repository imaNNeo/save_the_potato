import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/components/orb/orb_tail_particles.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import '../../my_game.dart';

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

  final OrbType type;
  final double speed;
  final PositionComponent target;

  Random get rnd => game.rnd;

  double get radius => size.x / 2;

  late List<Color> colors;
  late List<Sprite> smallSparkleSprites = [];

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
    colors = switch (type) {
      OrbType.red => GameConstants.redColors,
      OrbType.blue => GameConstants.blueColors,
    };

    smallSparkleSprites = await Future.wait(switch (type) {
      OrbType.red =>
        List.generate(2, (i) => Sprite.load('sparkle/sparkle${i + 1}.png')),
      OrbType.blue =>
        List.generate(2, (i) => Sprite.load('snow/snowflake${i + 1}.png')),
    });
    headPaint = Paint();
    disjointParticlePaint = Paint();
    add(CircleHitbox(collisionType: CollisionType.passive));
    add(OrbTailParticles());
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
          final sprite = smallSparkleSprites.random();
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
