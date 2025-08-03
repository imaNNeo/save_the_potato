import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/potato.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

import 'component_pool.dart';
import 'custom_particle.dart';
import 'moving/moving_components.dart';
import 'moving/orb/orb_type.dart';

class Shield extends PositionComponent
    with
        ParentIsA<Potato>,
        HasGameRef<PotatoGame>,
        CollisionCallbacks,
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

  final OrbType type;
  final double shieldWidth;
  final double shieldSweep;
  final double offset;

  late Timer _particleTimer;
  late List<Sprite> _flameSprites;
  late List<Sprite> _smallSparkleSprites;

  late Color shieldLineColor;
  late Color shieldTargetColor;

  late Paint flamePaint;
  late Paint sparklePaint;
  late Paint shieldLinePaint;

  late ComponentPool<CustomParticle> _shieldFlamePool;

  final _audioHelper = getIt.get<AudioHelper>();

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    timeScale = state.gameOverTimeScale;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
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

    _shieldFlamePool = ComponentPool<CustomParticle>(
      () => CustomParticle(),
      initialSize: 100,
    );

    shieldLineColor = type.baseColor.withValues(alpha: 0.0);
    shieldTargetColor = type.baseColor.withValues(alpha: 0.8);
    size = parent.size + Vector2.all(shieldWidth * 2) + Vector2.all(offset * 2);
    position = parent.size / 2;
    shieldLinePaint = Paint()
      ..color = type.baseColor
      ..strokeWidth = shieldWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    flamePaint = Paint();

    sparklePaint = Paint();
    _addHitbox();

    _flameSprites = [];
    for (int i = 1; i <= 8; i++) {
      _flameSprites.add(await Sprite.load('flame/flame$i.png'));
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

  final _opacityTween = Tween(begin: 0.4, end: 0.0);

  void _addParticles() {
    Random rnd = game.rnd;

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
        final trailParticle = _shieldFlamePool.get();
        trailParticle.startParticle(
          lifespan: 0.15,
          pool: _shieldFlamePool,
          angle: angle,
          anchor: Anchor.center,
          priority: -10,
          size: Vector2.zero(),
          position: Vector2.zero(),
          renderDelegate: (canvas, overridePaint, particle) {
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
                ..color = type.intenseColor.withValues(alpha: 0.2)
                ..style = PaintingStyle.stroke
                ..strokeCap = StrokeCap.round
                ..strokeWidth = 8,
            );
          },
        );
        parent.parent.add(trailParticle);

        // Main flames (inside and moving out)
        final mainFlame = _shieldFlamePool.get();
        mainFlame.startParticle(
            lifespan: 2.0,
            pool: _shieldFlamePool,
            position: localPos,
            size: spriteActualSize,
            anchor: Anchor.topLeft,
            acceleration: isShortFlame
                ? Vector2(
                    rnd.nextDouble() * 20,
                    -5 + rnd.nextDouble() * 10,
                  )
                : Vector2(
                    0,
                    -10 + rnd.nextDouble() * 20,
                  ),
            renderDelegate: (canvas, overridePaint, particle) {
              final opacity =
                  increaseDecreaseTween.transform(particle.progress);
              canvas.rotate(rotation);
              if (opacity <= 0.01) {
                return;
              }
              overridePaint.colorFilter = ColorFilter.mode(
                color.withValues(alpha: opacity),
                BlendMode.srcIn,
              );
              sprite.render(
                canvas,
                size: spriteActualSize,
                anchor: Anchor.center,
                overridePaint: overridePaint,
              );
            });
        add(mainFlame);

        // Sparkles (moving out)
        final extraParticle = _smallSparkleSprites.random(game.rnd);
        final sparkleParticle = _shieldFlamePool.get();
        sparkleParticle.startParticle(
          lifespan: 1.15,
          pool: _shieldFlamePool,
          acceleration: Vector2(
            (rnd.nextDouble() * 60) - 10,
            -7.5 + rnd.nextDouble() * 15,
          ),
          position: localPos,
          size: spriteActualSize / 2,
          anchor: Anchor.topLeft,
          renderDelegate: (canvas, overridePaint, particle) {
            final opacity = increaseDecreaseTween.transform(particle.progress);
            if (opacity <= 0.01) {
              return;
            }
            overridePaint.colorFilter = ColorFilter.mode(
              color.withValues(alpha: opacity),
              BlendMode.srcIn,
            );
            extraParticle.render(
              canvas,
              size: Vector2.all(opacity * 14),
              anchor: Anchor.center,
              overridePaint: overridePaint,
            );
          },
        );
        add(sparkleParticle);
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
      shieldLinePaint
        ..color = shieldLineColor
        ..strokeWidth = shieldWidth,
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is MovingComponent) {
      switch (other) {
        case MovingHealth():
          bloc.onShieldHit(other);
          _audioHelper.playShieldSound(bloc.state.shieldHitCounter);
          other.disjoint();
          break;
        case FireOrb():
        case IceOrb():
          final orb = other as MovingOrb;
          if ((orb.type.isFire && type.isFire) ||
              (orb.type.isIce && type.isIce)) {
            bloc.onShieldHit(other);
            if (orb.overrideCollisionSoundNumber != null) {
              _audioHelper.playShieldSound(orb.overrideCollisionSoundNumber!);
            } else {
              _audioHelper.playShieldSound(bloc.state.shieldHitCounter);
            }
            final orbPos = other.absolutePosition;
            final diff = orbPos - absolutePosition;
            final contactAngle = atan2(diff.y, diff.x);
            other.disjoint(contactAngle);
          }
          break;
      }
    }
  }

  @override
  void onRemove() {
    _particleTimer.stop();
    super.onRemove();
  }
}
