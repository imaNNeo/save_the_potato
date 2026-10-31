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
  late final double Function(double) _trailAtAngle = _trailAt;
  late final double Function(double) _currentAtAngle = _currentAt;

  /// A thin white-hot line on top of the shield when it's hot or powered up
  final _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  late Color _trailColor;
  static const _ashColor = Color(0xFF6B6B7A);

  /// How fast the shield turns, from 0 to 1, and which way (1 or -1)
  double _spin = 0;
  double _spinDirection = 1;
  double _trailLength = 0;
  double? _lastAngle;
  static const _maxTurnSpeed = pi * 1.8;

  /// The streak's heat and power, read once per frame
  double _heat = 0;
  double _power = 0;

  /// The shield bumps out when a chain of quick blocks is released
  double _releaseAge = double.infinity;
  double _releasePower = 0;
  static const _releaseDuration = 0.8;
  static final _releaseSpring = DampedSpring(
    frequency: 2 * pi * 5,
    damping: 0.3,
  );

  /// Flickers and greys out for a moment when a streak is lost
  double _fizzle = 0;
  int _lastStreakCount = 0;

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

    shieldLineColor = type.baseColor.withValues(alpha: 0.0);
    shieldTargetColor = type.baseColor.withValues(alpha: 0.8);
    _glowColor = Color.lerp(type.colors.first, Colors.white, 0.4)!;
    _auraColor = type.colors[1];
    _trailColor = type.intenseColor;
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
        // The hotter and more powered up, the bigger the flames
        final spriteActualSize =
            sprite.originalSize / 8 * (1 + _heat * 0.3 + _power * 0.6);

        /// -0.5 to 0.5
        final place = (generateAngle - angle) / (maxAngle - minAngle);
        final largeFlameAngle = place * (pi / 2);
        final shortFlameAngle = radians((rnd.nextDouble() * 20) - 5);
        final rotation = isShortFlame
            ? shortFlameAngle
            : pi / 2 + largeFlameAngle;

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
    final streak = _impacts.streak;
    _heat = streak.heat;
    _power = streak.power;
    // The hotter and more powered up, the more the shield burns
    _particleTimer.limit =
        lerpDouble(0.06, 0.042, _heat)! * (1 - _power * 0.45);
    _particleTimer.update(dt);
    _particles.update(dt);

    if (shieldLineColor != shieldTargetColor) {
      shieldLineColor = Color.lerp(shieldLineColor, shieldTargetColor, dt)!;
    }

    _time += dt;
    _updateTurning(dt);

    _flash = 0;
    for (var i = _hits.length - 1; i >= 0; i--) {
      final hit = _hits[i];
      hit.age += dt;
      if (hit.age >= _ShieldHit.duration) {
        _hits.removeAt(i);
        continue;
      }
      _flash += hit.strength * exp(-hit.age / 0.1);
    }
    _releaseAge += dt;
    if (_releaseAge < _releaseDuration) {
      _flash += _releasePower * exp(-_releaseAge / 0.12);
    }
    _flash = min(1.0, _flash);
    _aura = min(1.0, 0.35 * pow(_heat, 1.3) + _power * 0.45);

    if (_lastStreakCount >= 5 && streak.count == 0) {
      _fizzle = 1;
    }
    _lastStreakCount = streak.count;
    _fizzle = max(0, _fizzle - dt / 0.7);
    super.update(dt);
  }

  /// Follows how fast the shield turns, for its trail
  void _updateTurning(double dt) {
    if (dt <= 0) {
      return;
    }
    final lastAngle = _lastAngle ?? angle;
    _lastAngle = angle;
    var turn = (angle - lastAngle) % (2 * pi);
    if (turn > pi) {
      turn -= 2 * pi;
    }
    final turnSpeed = turn / dt;
    if (turnSpeed.abs() > 0.01) {
      _spinDirection = turnSpeed.sign;
    }
    final targetSpin = (turnSpeed.abs() / _maxTurnSpeed).clamp(0.0, 1.0);
    final rate = targetSpin > _spin ? 12.0 : 5.0;
    _spin += (targetSpin - _spin) * (1 - exp(-rate * dt));
    // Kept short so the shield is always easy to find
    _trailLength = 0.5 * _spin;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cx = size.x / 2, cy = size.y / 2;
    _linePath.reset();
    const segments = 24;
    for (var i = 0; i <= segments; i++) {
      final a = -shieldSweep / 2 + shieldSweep * i / segments;
      final r = _radiusAt(a);
      final x = cx + cos(a) * r;
      final y = cy + sin(a) * r;
      if (i == 0) {
        _linePath.moveTo(x, y);
      } else {
        _linePath.lineTo(x, y);
      }
    }

    var lineColor = Color.lerp(
      shieldLineColor,
      Colors.white,
      min(1.0, _flash * 0.7 + _heat * 0.12 + _power * 0.35),
    )!;
    if (_fizzle > 0) {
      final flicker = 0.6 + 0.4 * sin(_time * 50);
      lineColor = Color.lerp(lineColor, _ashColor, _fizzle * flicker)!;
    }
    shieldLinePaint
      ..color = lineColor
      ..strokeWidth = shieldWidth + _flash * 3 + _power * 4.5 + _heat;
    canvas.drawPath(_linePath, shieldLinePaint);

    final core = min(1.0, _smoothStep(0.35, 0.8, _heat) * 0.8 + _power * 0.8);
    if (core > 0.02 && _fizzle < 0.5) {
      _corePaint
        ..color = Colors.white.withValues(alpha: core * 0.85)
        ..strokeWidth = 1.4 + core;
      canvas.drawPath(_linePath, _corePaint);
    }

    _particles.render(canvas, _prepareParticle);

    _glow.clear();
    _addTrail(cx, cy);
    if (_aura > 0.01) {
      // The hotter the streak, the more the shield glows
      _glow.addArcBand(
        cx,
        cy,
        -shieldSweep / 2 - 0.1,
        shieldSweep + 0.2,
        30,
        26,
        _auraColor,
        _radiusAtAngle,
        _auraAtAngle,
      );
    }
    if (_power > 0.01) {
      // Every block powers it up, energy races along it
      _glow.addArcBand(
        cx,
        cy,
        -shieldSweep / 2 - 0.1,
        shieldSweep + 0.2,
        36,
        22,
        _glowColor,
        _radiusAtAngle,
        _currentAtAngle,
      );
    }
    if (_hits.isNotEmpty) {
      _glow.addArcBand(
        cx,
        cy,
        -shieldSweep / 2 - 0.1,
        shieldSweep + 0.2,
        30,
        20,
        _glowColor,
        _radiusAtAngle,
        _glowAtAngle,
      );
    }
    _addEmbers(cx, cy);
    _glow.render(canvas);
  }

  /// A soft glow under the shield that streams out behind it when it turns
  void _addTrail(double cx, double cy) {
    final lead = _spinDirection * shieldSweep / 2;
    _glow.addArcBand(
      cx,
      cy,
      lead,
      -_spinDirection * (shieldSweep + _trailLength),
      _spin > 0.02 ? 36 : 20,
      12 + _spin * 8,
      _trailColor,
      _radiusAtAngle,
      _trailAtAngle,
    );
    if (_spin > 0.05) {
      // The front edge cuts through the air
      final r = _radiusAt(lead);
      _glow.addDisc(
        cx + cos(lead) * r,
        cy + sin(lead) * r,
        9 + _spin * 7,
        _glowColor,
        _spin * 0.45,
      );
    }
  }

  /// Motes of energy running along a hot shield, more as it heats up
  void _addEmbers(double cx, double cy) {
    final embers = _heat * 7;
    for (var i = 0; i < embers.ceil(); i++) {
      final fade = min(1.0, embers - i);
      final a = sin(_time * (1.1 + 0.23 * i) + i * 2.4) * shieldSweep * 0.47;
      final r = _radiusAt(a) + 5 + 3 * sin(_time * 4 + i * 1.7);
      _glow.addDisc(
        cx + cos(a) * r,
        cy + sin(a) * r,
        5,
        _glowColor,
        0.75 * fade * (0.7 + 0.3 * sin(_time * 9 + i)),
      );
    }
  }

  /// The shields let a chain's charge go, [power] from 0 to 1
  void releaseCharge(double power) {
    _releaseAge = 0;
    _releasePower = power;
    final rnd = game.rnd;
    for (var i = 0; i < 6; i++) {
      final a = (rnd.nextDouble() - 0.5) * shieldSweep;
      _addFlare(a, rnd);
    }
  }

  /// Radius of the shield line at [angle] (in the shield's own angles)
  double _radiusAt(double angle) {
    var dent = 0.0;
    for (final hit in _hits) {
      final d = angle - hit.angle;
      dent += hit.dent * (0.3 + 0.7 * exp(-(d * d) / 0.2));
    }
    if (_releaseAge < _releaseDuration) {
      dent -= 5 * _releasePower * _releaseSpring.at(_releaseAge);
    }
    return _lineRadius - dent;
  }

  /// How bright the trail is at [angle]: soft under the shield, and while
  /// turning it streams out behind and fades
  double _trailAt(double angle) {
    final body = 0.12 + _spin * 0.3;
    // Measured the way the shield turns, its back end is at -sweep/2
    final behind = -shieldSweep / 2 - angle * _spinDirection;
    if (behind <= 0) {
      // Soft ends, but the back end flows into the tail while turning
      final soft = _trailLength <= 0 || angle * _spinDirection > 0;
      return soft ? body * _endsFade(angle) : body;
    }
    if (_trailLength <= 0) {
      return 0;
    }
    final f = max(0.0, 1 - behind / _trailLength);
    return body * f * f;
  }

  /// Pulses of energy racing along a powered up shield
  double _currentAt(double angle) {
    final pulse = 0.5 + 0.5 * sin(_time * 16 - angle * 9 * _spinDirection);
    return _power * 0.75 * (0.25 + 0.75 * pulse * pulse) * _endsFade(angle);
  }

  /// How bright the streak makes the shield glow at [angle]
  double _auraAt(double angle) =>
      _aura * (0.75 + 0.25 * sin(_time * 5 - angle * 6)) * _endsFade(angle);

  /// How bright the hits make the shield glow at [angle]
  double _glowAt(double angle) {
    var intensity = 0.0;
    for (final hit in _hits) {
      final t = hit.age;
      if (t >= _ShieldHit.glowDuration) {
        continue;
      }
      final d = angle - hit.angle;
      // Bright where it hit, spreading out
      final fade = 1 - t / _ShieldHit.glowDuration;
      final width = 0.12 + t * 0.75;
      intensity += fade * fade * hit.strength * exp(-(d * d) / (width * width));
      // And two waves running to the ends of the shield
      final travel = pi / 2 * (1 - pow(1 - min(1.0, t / 0.3), 2));
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
    final power = _impacts.streak.power;
    _hits.add(_ShieldHit(localAngle, strength: 1 + heat * 0.4 + power * 0.3));

    // The shield flares up where it was hit
    final rnd = game.rnd;
    for (var i = 0; i < 4; i++) {
      _addFlare(localAngle + (rnd.nextDouble() - 0.5) * 0.5, rnd);
    }
  }

  /// A flame bursting out of the shield at [a] (in the shield's own angles)
  void _addFlare(double a, Random rnd) {
    final sprite = _flameSprites[3 + rnd.nextInt(_flameSprites.length - 3)];
    final flare = _particles.spawn(sprite: sprite, lifespan: 0.65)
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

  static double _smoothStep(double from, double to, double value) {
    final t = ((value - from) / (to - from)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
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
            final rhythmHit = orb.rhythmHit;
            if (rhythmHit != null) {
              game.world.rhythm.onBlocked(orb, rhythmHit);
            } else if (orb.getOverrideCollisionSoundNumber() != null) {
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

  static const duration = 0.6;

  /// How long the shield glows after the hit
  static const glowDuration = 0.5;

  // The shield bends in, bounces out a little and rests
  static final _spring = DampedSpring(frequency: 2 * pi * 9, damping: 0.32);

  final double angle;
  final double strength;
  double age = 0;

  /// How deep the shield is bent in at [angle], in world units
  double get dent => 4.0 * strength * _spring.at(age);
}
