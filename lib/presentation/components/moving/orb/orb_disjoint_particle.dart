import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/my_game.dart';

class OrbDisjointParticleComponent extends Component
    with HasGameRef<MyGame>, ParentIsA<MovingOrb> {
  OrbDisjointParticleComponent({
    super.key,
    required this.colors,
    required this.smallSparkleSprites,
    required this.speedProgress,
  });

  final List<Color> colors;
  final List<Sprite> smallSparkleSprites;
  final double speedProgress;

  late Paint _disjointParticlePaint;

  Random get rnd => game.rnd;

  @override
  void onLoad() async {
    _disjointParticlePaint = Paint();
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
    final size = parent.size;
    await game.world.add(ParticleSystemComponent(
      position: parent.positionOfAnchor(Anchor.center),
      anchor: Anchor.center,
      particle: Particle.generate(
        count: 42,
        lifespan: 0.6 + ((1 - speedProgress) * 0.4),
        generator: (i) {
          final sprite = smallSparkleSprites.random();
          final extra = 200 * speedProgress;
          final halfExtra = extra == 0 ? 0 : extra / 2;
          return AcceleratedParticle(
            speed: Vector2(
              (rnd.nextDouble() * (200 + extra)) - (100 + halfExtra),
              (rnd.nextDouble() * (200 + extra)) - (100 + halfExtra),
            ),
            acceleration: Vector2(
              (rnd.nextDouble() * (200 + extra)) - (100 + halfExtra),
              (rnd.nextDouble() * (200 + extra)) - (100 + halfExtra),
            ),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = Tween(begin: 0.8, end: 0.0)
                    .chain(CurveTween(curve: Curves.easeInQuad))
                    .transform(particle.progress);
                if (opacity <= 0.01) {
                  return;
                }
                if (i % 3 == 0) {
                  final radius = size.x / 2;
                  canvas.drawCircle(
                    Offset.zero,
                    (radius * 0.7) * (1 - particle.progress),
                    _disjointParticlePaint
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
                    size: Vector2.all((size.x * 1.8) * (1 - particle.progress)),
                    anchor: Anchor.center,
                    overridePaint: _disjointParticlePaint
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
    removeFromParent();
  }
}