import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/widgets.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/my_game.dart';

class MovingOrbTailParticles extends Component with HasGameRef<MyGame> {
  late Paint particlePaint;

  final double _showEvery = 0.04;
  double _passedFromLastShow = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    particlePaint = Paint();
  }

  void _generateParticle() {
    if (parent is! MovingOrb) {
      throw Exception('Parent must be of type Orb');
    }
    final obrParent = (parent as MovingOrb);
    final color = obrParent.colors.random();
    final randomOrder = obrParent.colors.randomOrder();
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
    final sprite = obrParent.smallSparkleSprites.random();
    final rnd = obrParent.rnd;
    game.world.add(ParticleSystemComponent(
      position: obrParent.positionOfAnchor(Anchor.center),
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
                size: Vector2.all(
                  (obrParent.size.x * 0.7) * (1 - particle.progress),
                ),
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
