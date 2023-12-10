import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';

import '../cubit/game_cubit.dart';
import 'element_ball.dart';
import '../game_configs.dart';
import '../my_game.dart';
import 'player.dart';

class Shield extends PositionComponent
    with
        ParentIsA<Player>,
        HasGameRef<MyGame>,
        CollisionCallbacks,
        HasPaint,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
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
  late List<Sprite> _sparkleSprites;
  late List<Sprite> _snowflakeSprites;

  late Color shieldLineColor;
  late Color shieldTargetColor;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    timeScale = state.gameOverTimeScale;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    shieldLineColor = type.baseColor.withOpacity(0.0);
    shieldTargetColor = type.baseColor.withOpacity(0.8);
    size = parent.size + Vector2.all(shieldWidth * 2) + Vector2.all(offset * 2);
    position = parent.size / 2;
    paint = Paint()
      ..color = type.baseColor
      ..strokeWidth = shieldWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _addHitbox();

    _flameSprites = [];
    for (int i = 1; i <= 8; i++) {
      _flameSprites.add(await Sprite.load('flame/flame$i.png'));
    }

    _sparkleSprites = [];
    for (int i = 1; i <= 2; i++) {
      _sparkleSprites.add(await Sprite.load('sparkle/sparkle$i.png'));
    }

    _snowflakeSprites = [];
    for (int i = 1; i <= 2; i++) {
      _snowflakeSprites.add(await Sprite.load('snow/snowflake$i.png'));
    }

    _addParticles();
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

  void _addParticles() {
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
        final color = type.colors.random();

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
                    tween: Tween<double>(begin: 0.0, end: 0.8)
                        .chain(CurveTween(curve: Curves.easeIn)),
                    weight: 0.2,
                  ),
                  TweenSequenceItem<double>(
                    tween: Tween<double>(begin: 0.8, end: 0.0)
                        .chain(CurveTween(curve: Curves.easeOut)),
                    weight: 0.8,
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
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
                );
              },
            ),
          ),
        ));

        final extraParticle = switch (type) {
          TemperatureType.cold => _snowflakeSprites.random(),
          TemperatureType.hot => _sparkleSprites.random(),
        };
        add(ParticleSystemComponent(
          position: localPos,
          anchor: Anchor.center,
          particle: AcceleratedParticle(
            lifespan: 1.15,
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

              extraParticle.render(
                c,
                size: Vector2.all(opacity * 14),
                anchor: Anchor.center,
                overridePaint: Paint()
                  ..colorFilter = ColorFilter.mode(
                    color.withOpacity(opacity),
                    BlendMode.srcIn,
                  )
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
    canvas.drawArc(
      size.toRect().deflate(shieldWidth / 2),
      -shieldSweep / 2,
      shieldSweep,
      false,
      paint
        ..color = shieldLineColor
        ..strokeWidth = shieldWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ElementBall) {
      if (other.type == type) {
        other.dissolve();
      }
    }
  }

  @override
  void onRemove() {
    _particleTimer.stop();
    super.onRemove();
  }
}
