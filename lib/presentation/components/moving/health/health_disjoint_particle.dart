import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/my_game.dart';

class HealthDisjointParticleComponent extends Component
    with HasGameRef<MyGame>, ParentIsA<MovingHealth> {
  HealthDisjointParticleComponent({
    super.key,
    required this.colors,
    required this.smallSparkleSprites,
  });

  final List<Color> colors;
  final List<Sprite> smallSparkleSprites;

  late Paint _disjointParticlePaint;

  Random get rnd => game.rnd;

  @override
  void onLoad() async {
    _disjointParticlePaint = Paint();
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
    final size = parent.size;
    await game.world.add(ParticleSystemComponent(
      position: parent.positionOfAnchor(Anchor.center),
      anchor: Anchor.center,
      particle: Particle.generate(
        count: 8,
        lifespan: 3,
        generator: (i) {
          final sprite = smallSparkleSprites.random();
          final color = colors.random();
          final rotation = rnd.nextDouble() * pi * 4;
          return AcceleratedParticle(
            speed: Vector2(
              (rnd.nextDouble() * 300) - 150,
              (rnd.nextDouble() * 300) - 150,
            ),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = Tween(begin: 1.0, end: 0.0)
                    .chain(CurveTween(curve: Curves.easeOutCubic))
                    .transform(particle.progress);
                if (opacity <= 0.01) {
                  return;
                }
                canvas.rotate(particle.progress * rotation);
                sprite.render(
                  canvas,
                  size: Vector2.all((size.x) * (1 - particle.progress)),
                  anchor: Anchor.center,
                  overridePaint: _disjointParticlePaint
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
          );
        },
      ),
    ));
    removeFromParent();
  }
}
