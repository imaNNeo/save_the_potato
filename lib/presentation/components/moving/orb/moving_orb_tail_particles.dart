import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/custom_particle.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

class MovingOrbTailParticles extends Component with HasGameRef<PotatoGame> {
  late Paint particlePaint;

  final double _showEvery = 0.04;
  double _passedFromLastShow = 0.0;

  final opacityTween = Tween(begin: 0.8, end: 0.0).chain(
    CurveTween(curve: Curves.easeOutQuart),
  );

  late ComponentPool<CustomParticle> _particlePool;

  // setter
  set particlePool(ComponentPool<CustomParticle> pool) {
    _particlePool = pool;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    particlePaint = Paint();
  }

  void _generateParticle() {
    if (parent is! MovingOrb) {
      throw Exception('Parent must be of type Orb');
    }
    final parentOrb = (parent as MovingOrb);
    final color = parentOrb.colors.random();
    final randomOrder = parentOrb.colors.randomOrder();
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
    final sprite = parentOrb.smallSparkleSprites.random();
    final rnd = parentOrb.rnd;

    for (int index = 0; index < 2; index++) {
      final p = _particlePool.get();
      final randomBool = rnd.nextBool();
      p.startParticle(
        lifespan: 1.2,
        pool: _particlePool,
        position: parentOrb.positionOfAnchor(Anchor.center),
        acceleration: Vector2(
          (rnd.nextDouble() * 50) - (50 / 2),
          (rnd.nextDouble() * 50) - (50 / 2),
        ),
        renderDelegate: (canvas, overridePaint, particle) {
          final size = Vector2.all(
            (parentOrb.size.x * parentOrb.trailSizeMultiplier) *
                (1 - particle.progress),
          );
          final showingColor =
              (randomBool ? color : colorTween.transform(particle.progress))!;

          canvas.rotate(particle.progress * pi * 2);
          final alpha = opacityTween.transform(particle.progress);
          if (alpha <= 0.01) {
            return;
          }
          sprite.render(
            canvas,
            size: size,
            anchor: Anchor.center,
            overridePaint: overridePaint
              ..colorFilter = ColorFilter.mode(
                showingColor.withValues(
                  alpha: alpha,
                ),
                BlendMode.srcIn,
              ),
          );
        },
      );
      game.world.add(p);
    }
  }

  @override
  void update(double dt) {
    if (parent == null) {
      return;
    }
    _passedFromLastShow += dt;
    if (_passedFromLastShow >= _showEvery) {
      _passedFromLastShow = 0.0;
      _generateParticle();
    }
    super.update(dt);
  }
}
