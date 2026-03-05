import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:save_the_potato/presentation/components/component_pool.dart';
import 'package:save_the_potato/presentation/components/custom_particle.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

class MovingOrbTailParticles extends Component
    with HasGameReference<PotatoGame> {
  late Paint particlePaint;

  final double _showEvery = 0.04;
  double _passedFromLastShow = 0.0;

  final opacityTween = Tween(
    begin: 0.8,
    end: 0.0,
  ).chain(CurveTween(curve: Curves.easeOutQuart));

  late ComponentPool<CustomParticle> _particlePool;

  final _cachedSize = Vector2.zero();
  late List<TweenSequence<Color?>> _colorTweenVariants;

  // setter
  set particlePool(ComponentPool<CustomParticle> pool) {
    _particlePool = pool;
  }

  static List<TweenSequence<Color?>> _buildColorTweenVariants(
    List<Color> colors,
  ) {
    final permutations = <List<Color>>[];
    _permute(colors, 0, permutations);
    return permutations.map((perm) {
      return TweenSequence<Color?>([
        for (int i = 0; i < perm.length - 1; i++)
          TweenSequenceItem(
            weight: 1,
            tween: ColorTween(begin: perm[i], end: perm[i + 1]),
          ),
      ]);
    }).toList();
  }

  static void _permute(List<Color> list, int start, List<List<Color>> result) {
    if (start == list.length - 1) {
      result.add(List<Color>.from(list));
      return;
    }
    for (int i = start; i < list.length; i++) {
      final swapped = List<Color>.from(list);
      final temp = swapped[start];
      swapped[start] = swapped[i];
      swapped[i] = temp;
      _permute(swapped, start + 1, result);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    particlePaint = Paint();
    _colorTweenVariants = [];
  }

  void _generateParticle() {
    if (parent is! MovingOrb) {
      throw Exception('Parent must be of type Orb');
    }
    final parentOrb = (parent as MovingOrb);
    if (_colorTweenVariants.isEmpty) {
      _colorTweenVariants = _buildColorTweenVariants(parentOrb.colors);
    }
    final color = parentOrb.colors.random();
    final colorTween = _colorTweenVariants.random(game.rnd);
    final sprite = parentOrb.smallSparkleSprites.random();
    final rnd = parentOrb.rnd;

    for (int index = 0; index < 2; index++) {
      final p = _particlePool.get();
      final randomBool = rnd.nextBool();
      p.startParticle(
        lifespan: 1.2,
        pool: _particlePool,
        position: parentOrb.positionOfAnchor(Anchor.center),
        renderDelegate: (canvas, overridePaint, particle) {
          final s =
              (parentOrb.size.x * parentOrb.trailSizeMultiplier) *
              (1 - particle.progress);
          _cachedSize.setAll(s);
          final showingColor = (randomBool
              ? color
              : colorTween.transform(particle.progress))!;

          canvas.rotate(particle.progress * pi * 2);
          final alpha = opacityTween.transform(particle.progress);
          if (alpha <= 0.01) {
            return;
          }
          sprite.render(
            canvas,
            size: _cachedSize,
            anchor: Anchor.center,
            overridePaint: overridePaint
              ..colorFilter = ColorFilter.mode(
                showingColor.withValues(alpha: alpha),
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
