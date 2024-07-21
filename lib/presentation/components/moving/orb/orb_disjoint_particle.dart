import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

class OrbDisjointParticleComponent extends Component
    with HasGameRef<PotatoGame>, ParentIsA<MovingOrb> {
  OrbDisjointParticleComponent({
    super.key,
    required this.orbType,
    required this.colors,
    required this.smallSparkleSprites,
    required this.speedProgress,
    required this.contactAngle,
  });

  final OrbType orbType;
  final List<Color> colors;
  final List<Sprite> smallSparkleSprites;
  final double speedProgress;
  final double contactAngle;

  late Paint _disjointParticlePaint;
  final _cachedDirection = Vector2.zero();

  Random get rnd => game.rnd;

  double _getRandomConeAngle() {
    const coneAngle = pi * 1.1;
    final fromAngle = contactAngle - (coneAngle / 2);
    final toAngle = contactAngle + (coneAngle / 2);
    return fromAngle + rnd.nextDouble() * (toAngle - fromAngle);
  }

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
        count: 42,
        lifespan: 1.25 - (speedProgress * 0.4),
        generator: (i) {
          final color = colors.random(game.rnd);
          final sprite = smallSparkleSprites.random(game.rnd);
          final randomAngle = _getRandomConeAngle();
          _cachedDirection.setValues(cos(randomAngle), sin(randomAngle));
          return AcceleratedParticle(
            speed: _cachedDirection *
                (rnd.nextDouble() * 200 + (100 * speedProgress)),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacityBegin = lerpDouble(0.9, 0.6, speedProgress);
                const opacityEnd = 0.1;
                final opacity = Tween(begin: opacityBegin, end: opacityEnd)
                    .chain(CurveTween(curve: Curves.linear))
                    .transform(particle.progress);
                if (opacity <= 0.01) {
                  return;
                }
                /// We have different sizeScale for orb types,
                /// because snow particles seems larger in the result
                double sizeScale = orbType == OrbType.fire
                    ? lerpDouble(1.0, 0.5, particle.progress)!
                    : lerpDouble(0.8, 0.4, particle.progress)!;
                sizeScale *= lerpDouble(1.0, 0.8, speedProgress)!;
                if (i % 2 == 0) {
                  final radius = size.x / 2;
                  canvas.drawCircle(
                    Offset.zero,
                    (radius * 0.8) * sizeScale,
                    _disjointParticlePaint
                      ..colorFilter = null
                      ..maskFilter = null
                      ..color = color
                          .withOpacity(opacity),
                  );
                } else {
                  sprite.render(
                    canvas,
                    size: Vector2.all((size.x * 1.8) * sizeScale),
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
                }
              },
            ),
          );
        },
      ),
    ));
    add(RemoveEffect());
  }
}