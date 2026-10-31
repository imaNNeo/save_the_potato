import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/moving/moving_component_spawner.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'proto_events.dart';
import 'prototypes.dart';

/// Prototype 6: a boss every minute. "The Eclipse" is half fire, half ice.
/// It circles the potato and throws patterns, and every orb you block from
/// it takes one of its hit points. Beating it heals you and the next one is
/// tougher.
class BossFight extends Component with HasGameReference<PotatoGame> {
  static double get firstAt => Prototypes.number('bossAt') ?? 60;
  static const every = 60.0;

  /// Shown as a bar under the timer, null when there is no boss
  static final hp = ValueNotifier<double?>(null);

  late double _nextAt = firstAt;
  int _bossLevel = 0;
  _Boss? _boss;
  final _thrown = <MovingOrb>{};

  @override
  void onMount() {
    super.onMount();
    ProtoEvents.blockListeners.add(_onBlocked);
    hp.value = null;
  }

  @override
  void onRemove() {
    ProtoEvents.blockListeners.remove(_onBlocked);
    hp.value = null;
    ProtoHooks.pauseNormalSpawns = false;
    super.onRemove();
  }

  MovingComponentSpawner get _spawner =>
      game.world.children.whereType<MovingComponentSpawner>().first;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.playingState.isPlaying) {
      return;
    }
    final time = game.gameCubitState.levelTimePassed;
    if (_boss == null && time >= _nextAt) {
      // Let the normal orbs clear first
      ProtoHooks.pauseNormalSpawns = true;
      final orbsLeft = game.world.children.whereType<MovingComponent>().any(
        (c) => !c.isRemoved,
      );
      if (!orbsLeft) {
        _bossLevel++;
        game.world.add(
          _boss = _Boss(
            maxHp: 18 + 6 * (_bossLevel - 1),
            level: _bossLevel,
            fight: this,
          ),
        );
        game.background.milestone();
      }
    }
    _thrown.removeWhere((o) => o.isRemoved);
  }

  void throwOrb(OrbType type, Vector2 from, double speed) {
    _thrown.add(_spawner.throwOrb(type, from, speed));
  }

  void _onBlocked(MovingComponent orb) {
    final boss = _boss;
    if (boss == null || !_thrown.remove(orb)) {
      return;
    }
    boss.hit();
  }

  void _defeated() {
    _boss = null;
    hp.value = null;
    _nextAt = game.gameCubitState.levelTimePassed + every;
    ProtoHooks.pauseNormalSpawns = false;
    game.onHealthPointReceived();
  }
}

enum _Attack { volley, twin, spiral }

class _Boss extends PositionComponent with HasGameReference<PotatoGame> {
  _Boss({required this.maxHp, required this.level, required this.fight})
    : _hp = maxHp,
      super(anchor: Anchor.center, size: Vector2.all(_radius * 2), priority: 2);

  static const _radius = 42.0;
  static const _orbit = 225.0;

  final int maxHp;
  final int level;
  final BossFight fight;
  int _hp;

  double _time = 0;
  double _angle = -pi / 2;
  double _targetAngle = -pi / 2;
  double _enter = 0;
  double _dying = -1;
  double _flash = 0;

  _Attack _attack = _Attack.volley;
  int _attackIndex = 0;
  int _thrownInAttack = 0;
  double _cooldown = 1.6;
  double _sinceThrow = 0;

  double get _orbSpeed => 145.0 + 12 * level;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.playingState.isPlaying) {
      return;
    }
    _time += dt;
    _flash = max(0, _flash - dt * 4);
    _enter = min(1, _enter + dt / 1.4);
    if (_dying >= 0) {
      _dying += dt;
      if (_dying > 1.2) {
        removeFromParent();
      }
      return;
    }
    // Glide towards where the next attack comes from
    final speed = _attack == _Attack.spiral && _cooldown <= 0 ? 1.5 : 2.5;
    var diff = (_targetAngle - _angle) % (2 * pi);
    if (diff > pi) diff -= 2 * pi;
    if (_attack == _Attack.spiral && _cooldown <= 0) {
      _angle += speed * dt;
    } else {
      _angle += diff * min(1, dt * speed);
    }
    position = Vector2(cos(_angle), sin(_angle)) * _orbit;
    BossFight.hp.value = _hp / maxHp;
    if (_enter < 1) {
      return;
    }
    if (_cooldown > 0) {
      _cooldown -= dt;
      return;
    }
    _sinceThrow += dt;
    switch (_attack) {
      case _Attack.volley:
        if (_sinceThrow >= max(0.2, 0.32 - level * 0.03)) {
          _sinceThrow = 0;
          final type = _attackIndex.isEven ? OrbType.fire : OrbType.ice;
          fight.throwOrb(type, position.clone(), _orbSpeed);
          _next(5 + level);
        }
      case _Attack.twin:
        if (_sinceThrow >= 0.7) {
          _sinceThrow = 0;
          final swap = _thrownInAttack.isOdd;
          fight.throwOrb(
            swap ? OrbType.ice : OrbType.fire,
            position.clone(),
            _orbSpeed,
          );
          fight.throwOrb(
            swap ? OrbType.fire : OrbType.ice,
            -position,
            _orbSpeed,
          );
          _next(3 + level);
        }
      case _Attack.spiral:
        if (_sinceThrow >= 0.38) {
          _sinceThrow = 0;
          fight.throwOrb(
            _thrownInAttack.isEven ? OrbType.fire : OrbType.ice,
            position.clone(),
            _orbSpeed * 0.95,
          );
          _next(7 + level);
        }
    }
  }

  void _next(int count) {
    _thrownInAttack++;
    if (_thrownInAttack < count) {
      return;
    }
    _thrownInAttack = 0;
    _attackIndex++;
    _attack = _Attack.values[_attackIndex % _Attack.values.length];
    _cooldown = 1.3;
    _targetAngle =
        _angle +
        (ProtoHooks.rnd.nextBool() ? 1 : -1) *
            (pi / 2 + ProtoHooks.rnd.nextDouble() * pi / 2);
  }

  void hit() {
    if (_dying >= 0) {
      return;
    }
    _hp--;
    _flash = 1;
    BossFight.hp.value = _hp / maxHp;
    if (_hp <= 0) {
      _dying = 0;
      game.background.milestone();
      fight._defeated();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final enterScale = Curves.elasticOut.transform(_enter.clamp(0.0, 1.0));
    final dyingT = _dying < 0 ? 0.0 : (_dying / 1.2).clamp(0.0, 1.0);
    final scale = enterScale * (1 + dyingT * 1.6) * (1 + _flash * 0.12);
    final alpha = 1 - dyingT;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);

    final fire = GameConstants.redColors;
    final ice = GameConstants.blueColors;
    final pulse = 0.5 + 0.5 * sin(_time * 3);

    // Glow
    canvas.drawCircle(
      Offset.zero,
      _radius * 2.4,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.25 * alpha),
                fire[1].withValues(alpha: 0.18 * alpha),
                ice[1].withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: _radius * 2.4),
            ),
    );

    // Body: fire on one side, ice on the other, slowly turning
    canvas.save();
    canvas.rotate(_time * 0.6);
    final rect = Rect.fromCircle(center: Offset.zero, radius: _radius);
    canvas.drawArc(
      rect,
      pi / 2,
      pi,
      true,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, 0),
          colors: [fire[0], fire[1], fire[2]],
        ).createShader(rect)
        ..color = Colors.white.withValues(alpha: alpha),
    );
    canvas.drawArc(
      rect,
      -pi / 2,
      pi,
      true,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.3, 0),
          colors: [ice[0], ice[1], ice[2]],
        ).createShader(rect),
    );
    // A bright seam between the halves
    canvas.drawLine(
      const Offset(0, -_radius),
      const Offset(0, _radius),
      Paint()
        ..color = Colors.white.withValues(alpha: (0.6 + 0.4 * pulse) * alpha)
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.restore();

    // Angry eyes, always level
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
    final pupilPaint = Paint()
      ..color = const Color(0xFF1A0B2E).withValues(alpha: alpha);
    final browPaint = Paint()
      ..color = const Color(0xFF1A0B2E).withValues(alpha: alpha)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // Looks at the potato, which sits at the world origin
    final look = Offset(-cos(_angle), -sin(_angle)) * 3;
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(side * 11, -2);
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: 13, height: 11),
        eyePaint,
      );
      canvas.drawCircle(eye + look, 3.6, pupilPaint);
      canvas.drawLine(
        eye + Offset(-side * 8, -11),
        eye + Offset(side * 6, -5),
        browPaint,
      );
    }
    // Frown
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, 16), width: 16, height: 9),
      pi + 0.3,
      pi - 0.6,
      false,
      browPaint..strokeWidth = 3,
    );

    // Hit points ring
    final ring = Rect.fromCircle(center: Offset.zero, radius: _radius + 9);
    canvas.drawArc(
      ring,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.15 * alpha),
    );
    canvas.drawArc(
      ring,
      -pi / 2,
      2 * pi * (_hp / maxHp),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(
          const Color(0xFFFF2E6B),
          Colors.white,
          _flash,
        )!.withValues(alpha: alpha),
    );

    if (_flash > 0) {
      canvas.drawCircle(
        Offset.zero,
        _radius,
        Paint()..color = Colors.white.withValues(alpha: _flash * 0.6),
      );
    }
    canvas.restore();
  }
}
