import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import 'element_ball.dart';
import 'my_game.dart';
import 'player.dart';

class Shield extends PositionComponent
    with ParentIsA<Player>, HasGameRef<MyGame>, CollisionCallbacks, HasPaint {
  Shield({
    required this.type,
    this.shieldWidth = 6.0,
    this.shieldSweep = pi / 2,
    this.offset = 12,
  }) : super(
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  final TemperatureType type;
  final double shieldWidth;
  final double shieldSweep;
  final double offset;

  late Timer _particleTimer;
  late List<Sprite> _flameSprites;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = parent.size + Vector2.all(shieldWidth * 2) + Vector2.all(offset * 2);
    position = parent.size / 2;
    paint = Paint()
      ..color = type.color
      ..strokeWidth = shieldWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _addHitbox();

    _flameSprites = [];
    for (int i = 1; i <= 8; i++) {
      _flameSprites.add(await Sprite.load('flame/flame$i.png'));
    }

    switch (type) {
      case TemperatureType.cold:
        _addColdParticles();
        break;
      case TemperatureType.hot:
        _addHotParticles();
        break;
    }
  }

  void _addHitbox() {
    final center = size / 2;

    const precision = 8;

    final segment = shieldSweep / (precision - 1);
    final radius = size.x / 2;
    final startAngle = 0 - shieldSweep / 2;

    List<Vector2> vertices = [];
    for (int i = 0; i < precision; i++) {
      final thisSegment = startAngle + segment * i;
      vertices.add(
        center + Vector2(cos(thisSegment), sin(thisSegment)) * radius,
      );
    }

    for (int i = precision - 1; i >= 0; i--) {
      final thisSegment = startAngle + segment * i;
      vertices.add(
        center +
            Vector2(cos(thisSegment), sin(thisSegment)) *
                (radius - shieldWidth),
      );
    }

    add(PolygonHitbox(
      vertices,
      collisionType: CollisionType.active,
    ));
  }

  void _addColdParticles() {
    Random rnd = Random();

    _particleTimer = Timer(
      0.04,
      onTick: () {
        final radius = (size.x / 2) - shieldWidth / 2;
        final minAngle = angle - (shieldSweep / 2);
        final maxAngle = angle + (shieldSweep / 2);
        final generateAngle =
            minAngle + rnd.nextDouble() * (maxAngle - minAngle);
        final localPos = (size / 2) +
            Vector2(cos(generateAngle - angle), sin(generateAngle - angle)) *
                radius;
        final color = game.coldColors.random();

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
                final opacity = TweenSequence<double>([
                  TweenSequenceItem<double>(
                    tween: Tween<double>(begin: 0.0, end: 0.5)
                        .chain(CurveTween(curve: Curves.easeIn)),
                    weight: 0.5,
                  ),
                  TweenSequenceItem<double>(
                    tween: Tween<double>(begin: 0.5, end: 0.0)
                        .chain(CurveTween(curve: Curves.easeOut)),
                    weight: 0.5,
                  ),
                ]).transform(particle.progress);
                canvas.rotate(rotation);
                sprite.render(
                  canvas,
                  size: spriteActualSize,
                  anchor: Anchor.center,
                  overridePaint: Paint()
                    ..colorFilter = ColorFilter.mode(
                      color.withOpacity(opacity),
                      BlendMode.srcIn,
                    )
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
                );
              },
            ),
          ),
        ));
        add(ParticleSystemComponent(
          position: localPos,
          anchor: Anchor.center,
          particle: AcceleratedParticle(
            lifespan: 1,
            acceleration: Vector2(
              (rnd.nextDouble() * 120) - 20,
              -15 + rnd.nextDouble() * 30,
            ),
            position: Vector2.zero(),
            child: ComputedParticle(renderer: (Canvas c, Particle particle) {
              final opacity = TweenSequence<double>([
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
              ]).transform(particle.progress);
              c.drawCircle(
                Offset.zero,
                opacity * 1,
                Paint()
                  ..color = color.withOpacity(opacity)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
              );
            }),
          ),
        ));
      },
      repeat: true,
    );
    _particleTimer.start();
  }

  void _addHotParticles() {
    Random rnd = Random();

    _particleTimer = Timer(
      0.04,
      onTick: () {
        final radius = (size.x / 2) - shieldWidth / 2;
        final minAngle = angle - (shieldSweep / 2);
        final maxAngle = angle + (shieldSweep / 2);
        final generateAngle =
            minAngle + rnd.nextDouble() * (maxAngle - minAngle);
        final localPos = (size / 2) +
            Vector2(cos(generateAngle - angle), sin(generateAngle - angle)) *
                radius;
        final color = game.hotColors.random();

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
                final opacity = TweenSequence<double>([
                  TweenSequenceItem<double>(
                    tween: Tween<double>(begin: 0.0, end: 0.5)
                        .chain(CurveTween(curve: Curves.easeIn)),
                    weight: 0.5,
                  ),
                  TweenSequenceItem<double>(
                    tween: Tween<double>(begin: 0.5, end: 0.0)
                        .chain(CurveTween(curve: Curves.easeOut)),
                    weight: 0.5,
                  ),
                ]).transform(particle.progress);
                canvas.rotate(rotation);
                sprite.render(
                  canvas,
                  size: spriteActualSize,
                  anchor: Anchor.center,
                  overridePaint: Paint()
                    ..colorFilter = ColorFilter.mode(
                      color.withOpacity(opacity),
                      BlendMode.srcIn,
                    )
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
                );
              },
            ),
          ),
        ));
        add(ParticleSystemComponent(
          position: localPos,
          anchor: Anchor.center,
          particle: AcceleratedParticle(
            lifespan: 1,
            acceleration: Vector2(
              (rnd.nextDouble() * 120) - 20,
              -15 + rnd.nextDouble() * 30,
            ),
            position: Vector2.zero(),
            child: ComputedParticle(renderer: (Canvas c, Particle particle) {
              final opacity = TweenSequence<double>([
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
              ]).transform(particle.progress);
              c.drawCircle(
                Offset.zero,
                opacity * 1,
                Paint()
                  ..color = color.withOpacity(opacity)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
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
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawArc(
      size.toRect().deflate(shieldWidth / 2),
      -shieldSweep / 2,
      shieldSweep,
      false,
      paint
        ..color = type.color.withOpacity(0.8)
        ..strokeWidth = shieldWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ElementBall) {
      if (other.type == type) {
        other.removeFromParent();
      }
    }
  }

  @override
  void onRemove() {
    _particleTimer.stop();
    super.onRemove();
  }
}
