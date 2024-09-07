import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/widgets.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/shield/shield.dart';
import 'package:save_the_potato/presentation/potato_game.dart';


class ShieldUiStyle1 extends PositionComponent
    with ParentIsA<Shield>, HasGameRef<PotatoGame> {
  late Timer _particleTimer;
  late List<Sprite> _flameSprites;
  late List<Sprite> _smallSparkleSprites;

  late Color shieldLineColor;
  late Color shieldTargetColor;

  late Paint flamePaint;
  late Paint sparklePaint;
  late Paint shieldLinePaint;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = parent.size;
    final type = parent.type;
    final shieldWidth = parent.shieldWidth;
    _smallSparkleSprites = switch (type) {
      OrbType.fire => [
        await Sprite.load('sparkle/sparkle1.png'),
        await Sprite.load('sparkle/sparkle2.png'),
      ],
      OrbType.ice => [
        await Sprite.load('snow/snowflake1.png'),
        await Sprite.load('snow/snowflake2.png'),
      ],
    };

    shieldLineColor = type.baseColor.withOpacity(0.0);
    shieldTargetColor = type.baseColor.withOpacity(0.8);
    shieldLinePaint = Paint()
      ..color = type.baseColor
      ..strokeWidth = shieldWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    flamePaint = Paint();

    sparklePaint = Paint();

    _flameSprites = [];
    for (int i = 1; i <= 8; i++) {
      _flameSprites.add(await Sprite.load('flame/flame$i.png'));
    }

    _addParticles();
  }

  final _opacityTween = Tween(begin: 0.4, end: 0.0);

  void _addParticles() {
    Random rnd = game.rnd;
    final shieldWidth = parent.shieldWidth;
    final shieldSweep = parent.shieldSweep;
    final type = parent.type;
    final increaseDecreaseTween = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.8, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
    ]);
    _particleTimer = Timer(
      0.06,
      onTick: () {
        final angle = parent.angle;
        final radius = (size.x / 2) - shieldWidth / 2;
        final minAngle = angle - (shieldSweep / 2);
        final maxAngle = angle + (shieldSweep / 2);
        final generateAngle =
            minAngle + rnd.nextDouble() * (maxAngle - minAngle);

        final localPos = (size / 2) +
            Vector2(
              cos(generateAngle - angle),
              sin(generateAngle - angle),
            ) *
                radius;
        final color = type.colors.random(game.rnd);

        final spriteIndex = rnd.nextInt(_flameSprites.length);
        final isShortFlame = spriteIndex <= 2;
        final sprite = _flameSprites[spriteIndex];
        final spriteActualSize = sprite.originalSize / 8;

        /// -0.5 to 0.5
        final place = (generateAngle - angle) / (maxAngle - minAngle);
        final largeFlameAngle = place * (pi / 2);
        final shortFlameAngle = radians((rnd.nextDouble() * 20) - 5);
        final rotation =
        isShortFlame ? shortFlameAngle : pi / 2 + largeFlameAngle;

        /// Trail
        final myWorld = game.world;
        myWorld.add(ParticleSystemComponent(
          priority: -10,
          angle: angle,
          anchor: Anchor.center,
          particle: ComputedParticle(
            lifespan: 0.15,
            renderer: (canvas, particle) {
              final opacity = _opacityTween.transform(particle.progress);
              if (opacity <= 0.01) {
                return;
              }
              canvas.drawArc(
                Rect.fromCircle(
                  center: Offset.zero,
                  radius: radius,
                ),
                -(shieldSweep / 2),
                shieldSweep,
                false,
                Paint()
                  ..color = type.intenseColor.withOpacity(0.2)
                  ..style = PaintingStyle.stroke
                  ..strokeCap = StrokeCap.round
                  ..strokeWidth = 8,
              );
            },
          ),
        ));

        // Main flames (inside and moving out)
        add(ParticleSystemComponent(
          position: localPos,
          anchor: Anchor.center,
          particle: AcceleratedParticle(
            lifespan: 2,
            acceleration: isShortFlame
                ? Vector2(
              rnd.nextDouble() * 40,
              -10 + rnd.nextDouble() * 20,
            )
                : Vector2(
              0,
              -20 + rnd.nextDouble() * 40,
            ),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = increaseDecreaseTween.transform(
                  particle.progress,
                );
                canvas.rotate(rotation);
                if (opacity <= 0.01) {
                  return;
                }
                sprite.render(
                  canvas,
                  size: spriteActualSize,
                  anchor: Anchor.center,
                  overridePaint: flamePaint
                    ..colorFilter = ColorFilter.mode(
                      color.withOpacity(opacity),
                      BlendMode.srcIn,
                    ),
                );
              },
            ),
          ),
        ));

        // Sparkles (moving out)
        final extraParticle = _smallSparkleSprites.random(game.rnd);
        add(ParticleSystemComponent(
          position: localPos,
          anchor: Anchor.center,
          particle: AcceleratedParticle(
            lifespan: 1.15,
            acceleration: Vector2(
              (rnd.nextDouble() * 120) - 20,
              -15 + rnd.nextDouble() * 30,
            ),
            child: ComputedParticle(renderer: (Canvas c, Particle particle) {
              final opacity =
              increaseDecreaseTween.transform(particle.progress);

              if (opacity <= 0.01) {
                return;
              }
              extraParticle.render(
                c,
                size: Vector2.all(opacity * 14),
                anchor: Anchor.center,
                overridePaint: sparklePaint
                  ..colorFilter = ColorFilter.mode(
                    color.withOpacity(opacity),
                    BlendMode.srcIn,
                  ),
              );
            }),
          ),
        ));
      },
      repeat: true,
    );
    _particleTimer.start();
  }

  @override
  void update(double dt) {
    _particleTimer.update(dt);

    if (shieldLineColor != shieldTargetColor) {
      shieldLineColor = ColorTween(
        begin: shieldLineColor,
        end: shieldTargetColor,
      ).lerp(dt)!;
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final shieldWidth = parent.shieldWidth;
    final shieldSweep = parent.shieldSweep;
    canvas.drawArc(
      size.toRect().deflate(shieldWidth / 2),
      -shieldSweep / 2,
      shieldSweep,
      false,
      shieldLinePaint
        ..color = shieldLineColor
        ..strokeWidth = shieldWidth,
    );
  }

  @override
  void onRemove() {
    _particleTimer.stop();
    super.onRemove();
  }
}