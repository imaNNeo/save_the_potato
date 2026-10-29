import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide ComponentPool;
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
import 'damped_spring.dart';
import 'glow_batch.dart';
import 'shield_impact_effects.dart';
import 'sprite_particle_batch.dart';
import 'moving/moving_components.dart';
import 'moving/orb/orb_type.dart';

class Shield extends PositionComponent
    with
        ParentIsA<Potato>,
        HasGameReference<PotatoGame>,
        CollisionCallbacks,
        HasTimeScale,
        FlameBlocListenable<GameCubit, GameState> {
  Shield({
    required this.type,
    this.shieldWidth = 6.0,
    this.shieldSweep = pi / 2,
    this.offset = 12,
  }) : super(position: Vector2.all(0), anchor: Anchor.center);

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
  late Paint _trailPaint;

  late ComponentPool<CustomParticle> _shieldFlamePool;

  /// Flames and sparkles, drawn in one batch (there are ~50 alive per shield)
  final _particles = SpriteParticleBatch();
  static const _particleKindFlame = 0;
  static const _particleKindSparkle = 1;
  static const _particleKindFlare = 2;

  final _audioHelper = getIt.get<AudioHelper>();

  /// Orbs that hit the shield recently, they bend it and light it up
  final _hits = <_ShieldHit>[];
  static const _maxHits = 4;

  /// The glow along the shield, from hits and from the streak's heat
  final _glow = GlowBatch();
  late Color _glowColor;
  late Color _auraColor;
  final _linePath = Path();
  late double _lineRadius;
  double _flash = 0;
  double _aura = 0;
  double _time = 0;
  late final double Function(double) _radiusAtAngle = _radiusAt;
  late final double Function(double) _glowAtAngle = _glowAt;
  late final double Function(double) _auraAtAngle = _auraAt;

  ShieldImpactEffects get _impacts => game.world.shieldImpacts;

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.gameOverTimeScale != newState.gameOverTimeScale;

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
      initialSize: 5,
      debugName: 'Shield trail',
    );

    shieldLineColor = type.baseColor.withValues(alpha: 0.0);
    shieldTargetColor = type.baseColor.withValues(alpha: 0.8);
    _glowColor = Color.lerp(type.colors.first, Colors.white, 0.4)!;
    _auraColor = type.colors[1];
    size = parent.size + Vector2.all(shieldWidth * 2) + Vector2.all(offset * 2);
    position = parent.size / 2;
    _lineRadius = size.x / 2 - shieldWidth / 2;
    shieldLinePaint = Paint()
      ..color = type.baseColor
      ..strokeWidth = shieldWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    flamePaint = Paint();

    sparklePaint = Paint();

    _trailPaint = Paint()
      ..color = type.intenseColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
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

    add(PolygonHitbox(vertices, collisionType: CollisionType.active));
  }

  final _opacityTween = Tween(begin: 0.4, end: 0.0);
  late TweenSequence<double> _increaseDecreaseTween;

  void _addParticles() {
    Random rnd = game.rnd;

    _increaseDecreaseTween = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.8,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
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

        final localPos =
            (size / 2) +
            Vector2(cos(generateAngle - angle), sin(generateAngle - angle)) *
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
        final rotation = isShortFlame
            ? shortFlameAngle
            : pi / 2 + largeFlameAngle;

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
              Rect.fromCircle(center: Offset.zero, radius: radius),
              -(shieldSweep / 2),
              shieldSweep,
              false,
              _trailPaint,
            );
          },
        );
        parent.parent.add(trailParticle);

        // Main flames (inside and moving out)
        final mainFlame = _particles.spawn(sprite: sprite, lifespan: 2.0)
          ..kind = _particleKindFlame
          ..color = color
          ..drawScale = spriteActualSize.x / sprite.src.width
          ..drawRotation = rotation;
        mainFlame.position.setFrom(localPos);
        if (isShortFlame) {
          mainFlame.acceleration.setValues(
            rnd.nextDouble() * 20,
            -5 + rnd.nextDouble() * 10,
          );
        } else {
          mainFlame.acceleration.setValues(0, -10 + rnd.nextDouble() * 20);
        }

        // Sparkles (moving out)
        final sparkle =
            _particles.spawn(
                sprite: _smallSparkleSprites.random(game.rnd),
                lifespan: 1.15,
              )
              ..kind = _particleKindSparkle
              ..color = color
              ..drawRotation = 0;
        sparkle.position.setFrom(localPos);
        sparkle.acceleration.setValues(
          (rnd.nextDouble() * 60) - 10,
          -7.5 + rnd.nextDouble() * 15,
        );
      },
      repeat: true,
    );
    _particleTimer.start();
  }

  @override
  void update(double dt) {
    final heat = _impacts.streak.heat;
    // The hotter the streak, the more the shield burns
    _particleTimer.limit = lerpDouble(0.06, 0.042, heat)!;
    _particleTimer.update(dt);
    _particles.update(dt);

    if (shieldLineColor != shieldTargetColor) {
      shieldLineColor = Color.lerp(shieldLineColor, shieldTargetColor, dt)!;
    }

    _time += dt;
    _flash = 0;
    for (var i = _hits.length - 1; i >= 0; i--) {
      final hit = _hits[i];
      hit.age += dt;
      if (hit.age >= _ShieldHit.duration) {
        _hits.removeAt(i);
        continue;
      }
      _flash += hit.strength * exp(-hit.age / 0.07);
    }
    _flash = min(1.0, _flash);
    _aura = 0.35 * pow(heat, 1.3);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final heat = _impacts.streak.heat;
    shieldLinePaint
      ..color = Color.lerp(
        shieldLineColor,
        Colors.white,
        min(1.0, _flash * 0.7 + heat * 0.12),
      )!
      ..strokeWidth = shieldWidth + _flash * 3;
    if (_hits.isEmpty) {
      canvas.drawArc(
        size.toRect().deflate(shieldWidth / 2),
        -shieldSweep / 2,
        shieldSweep,
        false,
        shieldLinePaint,
      );
    } else {
      // Bent by the hits
      _linePath.reset();
      const segments = 24;
      for (var i = 0; i <= segments; i++) {
        final a = -shieldSweep / 2 + shieldSweep * i / segments;
        final r = _radiusAt(a);
        final x = size.x / 2 + cos(a) * r;
        final y = size.y / 2 + sin(a) * r;
        if (i == 0) {
          _linePath.moveTo(x, y);
        } else {
          _linePath.lineTo(x, y);
        }
      }
      canvas.drawPath(_linePath, shieldLinePaint);
    }
    _particles.render(canvas, _prepareParticle);

    if (_hits.isEmpty && _aura <= 0.01) {
      return;
    }
    _glow.clear();
    if (_aura > 0.01) {
      // The hotter the streak, the more the shield glows
      _glow.addArcBand(
        size.x / 2,
        size.y / 2,
        -shieldSweep / 2 - 0.1,
        shieldSweep + 0.2,
        30,
        26,
        _auraColor,
        _radiusAtAngle,
        _auraAtAngle,
      );
    }
    if (_hits.isNotEmpty) {
      _glow.addArcBand(
        size.x / 2,
        size.y / 2,
        -shieldSweep / 2 - 0.1,
        shieldSweep + 0.2,
        30,
        20,
        _glowColor,
        _radiusAtAngle,
        _glowAtAngle,
      );
    }
    _glow.render(canvas);
  }

  /// Radius of the shield line at [angle] (in the shield's own angles)
  double _radiusAt(double angle) {
    var dent = 0.0;
    for (final hit in _hits) {
      final d = angle - hit.angle;
      dent += hit.dent * (0.3 + 0.7 * exp(-(d * d) / 0.2));
    }
    return _lineRadius - dent;
  }

  /// How bright the streak makes the shield glow at [angle]
  double _auraAt(double angle) =>
      _aura * (0.75 + 0.25 * sin(_time * 5 - angle * 6)) * _endsFade(angle);

  /// How bright the hits make the shield glow at [angle]
  double _glowAt(double angle) {
    var intensity = 0.0;
    for (final hit in _hits) {
      final t = hit.age;
      if (t >= 0.3) {
        continue;
      }
      final d = angle - hit.angle;
      // Bright where it hit, spreading out
      final fade = 1 - t / 0.3;
      final width = 0.12 + t * 1.1;
      intensity += fade * fade * hit.strength * exp(-(d * d) / (width * width));
      // And two waves running to the ends of the shield
      final travel = pi / 2 * (1 - pow(1 - min(1.0, t / 0.22), 2));
      final wave = 0.9 * pow(fade, 1.5) * hit.strength;
      final d1 = d - travel, d2 = d + travel;
      intensity += wave * (exp(-(d1 * d1) / 0.01) + exp(-(d2 * d2) / 0.01));
    }
    return min(1.0, intensity * _endsFade(angle));
  }

  /// Glows fade out past the ends of the shield
  double _endsFade(double angle) {
    final outside = angle.abs() - shieldSweep / 2;
    if (outside <= -0.08) {
      return 1;
    }
    return (1 - (outside + 0.08) / 0.18).clamp(0.0, 1.0);
  }

  void _onOrbBlocked(double contactAngle) {
    _impacts.onOrbBlocked(
      type: type,
      center: absolutePosition,
      angle: contactAngle,
      radius: size.x / 2,
    );
    final heat = _impacts.streak.targetHeat;

    var localAngle = (contactAngle - angle) % (2 * pi);
    if (localAngle > pi) {
      localAngle -= 2 * pi;
    }
    if (_hits.length >= _maxHits) {
      _hits.removeAt(0);
    }
    _hits.add(_ShieldHit(localAngle, strength: 1 + heat * 0.4));

    // The shield flares up where it was hit
    final rnd = game.rnd;
    for (var i = 0; i < 4; i++) {
      final a = localAngle + (rnd.nextDouble() - 0.5) * 0.5;
      final sprite = _flameSprites[3 + rnd.nextInt(_flameSprites.length - 3)];
      final flare = _particles.spawn(sprite: sprite, lifespan: 0.45)
        ..kind = _particleKindFlare
        ..color = type.colors.random(rnd)
        ..drawScale = (1.0 + rnd.nextDouble() * 0.4) / 8
        ..drawRotation = a + (rnd.nextDouble() - 0.5) * 0.4;
      flare.position.setValues(
        size.x / 2 + cos(a) * _lineRadius,
        size.y / 2 + sin(a) * _lineRadius,
      );
      final push = 50 + rnd.nextDouble() * 50;
      flare.acceleration.setValues(cos(a) * push, sin(a) * push);
    }
  }

  bool _prepareParticle(SpriteParticle particle) {
    if (particle.kind == _particleKindFlare) {
      final opacity = pow(1 - particle.progress, 1.5).toDouble();
      if (opacity <= 0.01) {
        return false;
      }
      particle.drawOpacity = opacity;
      return true;
    }
    final opacity = _increaseDecreaseTween.transform(particle.progress);
    if (opacity <= 0.01) {
      return false;
    }
    particle.drawOpacity = opacity;
    if (particle.kind == _particleKindSparkle) {
      particle.drawScale = opacity * 14 / particle.sprite.src.width;
    }
    return true;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
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
          if (orb.type == type) {
            bloc.onShieldHit(other);
            if (orb.getOverrideCollisionSoundNumber() != null) {
              _audioHelper.playShieldSound(
                orb.getOverrideCollisionSoundNumber()!,
              );
            } else {
              _audioHelper.playShieldSound(bloc.state.shieldHitCounter);
            }
            final orbPos = other.absolutePosition;
            final diff = orbPos - absolutePosition;
            _onOrbBlocked(atan2(diff.y, diff.x));
            other.disjoint();
          }
          break;
      }
    }
  }

  @override
  void onRemove() {
    _particleTimer.stop();
    _particles.clear();
    _hits.clear();
    super.onRemove();
  }
}

/// An orb hitting the shield at [angle] (in the shield's own angles)
class _ShieldHit {
  _ShieldHit(this.angle, {required this.strength});

  static const duration = 0.45;

  // The shield bends in, bounces out a little and rests
  static final _spring = DampedSpring(frequency: 2 * pi * 9, damping: 0.32);

  final double angle;
  final double strength;
  double age = 0;

  /// How deep the shield is bent in at [angle], in world units
  double get dent => 4.0 * strength * _spring.at(age);
}
