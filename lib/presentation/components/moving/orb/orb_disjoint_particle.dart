import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/animation.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/custom_particle.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

class OrbDisjointParticleComponent extends Component
    with HasGameRef<PotatoGame>, ParentIsA<MovingOrb> {
  OrbDisjointParticleComponent({
    super.key,
  });

  late OrbType orbType;
  late List<Color> colors;
  late List<Sprite> smallSparkleSprites;
  late double speedProgress;
  late double contactAngle;

  late Paint _disjointParticlePaint;
  final _cachedDirection = Vector2.zero();

  Random get rnd => game.rnd;

  @override
  void onLoad() async {
    _disjointParticlePaint = Paint();
  }

  double _getRandomConeAngle() {
    const coneAngle = pi * 1.1;
    final fromAngle = contactAngle - (coneAngle / 2);
    final toAngle = contactAngle + (coneAngle / 2);
    return fromAngle + rnd.nextDouble() * (toAngle - fromAngle);
  }

  Future<void> burst({
    required OrbType orbType,
    required List<Color> colors,
    required List<Sprite> smallSparkleSprites,
    required double speedProgress,
    required double contactAngle,
    required ComponentPool<CustomParticle> particlePool,
  }) async {
    this.orbType = orbType;
    this.colors = colors;
    this.smallSparkleSprites = smallSparkleSprites;
    this.speedProgress = speedProgress;
    this.contactAngle = contactAngle;

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

    for (int i = 0; i < 42; i++) {
      final p = particlePool.get();
      final randomBool = rnd.nextBool();
      final color = colors.random(game.rnd);
      final sprite = smallSparkleSprites.random(game.rnd);
      final randomAngle = _getRandomConeAngle();
      _cachedDirection.setValues(cos(randomAngle), sin(randomAngle));
      final speed = _cachedDirection *
          (rnd.nextDouble() * 200 + (100 * speedProgress));
      p.startParticle(
        lifespan: 1.25 - (speedProgress * 0.4),
        pool: particlePool,
        position: parent.positionOfAnchor(Anchor.center),
        acceleration: speed,
        renderDelegate: (canvas, overridePaint, particle) {
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
                    .withValues(alpha: opacity),
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
                      .withValues(alpha: opacity),
                  BlendMode.srcIn,
                ),
            );
          }
        },
      );
      game.world.add(p);
    }
    add(RemoveEffect());
  }
}