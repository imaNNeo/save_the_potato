import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/components/shield.dart';

double _clamp01(double x) => x.clamp(0.0, 1.0);

const _missColor = Color(0xFFFF3B4E);
const _white = Color(0xFFFFFFFF);
const _good = Color(0xFF6BFFA8);

/// A ring of dots around the potato, one for each orb the player has to
/// block. Each block fills one, a hit shakes them red, and when all are
/// full they burst out to the arena edge as the real game starts.
class TutorialProgressDots extends PositionComponent {
  TutorialProgressDots({required this.count}) : super(priority: 2);

  final int count;

  static const _radius = 122.0;
  static const _dotRadius = 5.5;

  final _fills = <double>[];
  final _colors = <Color>[];
  int _filled = 0;

  double _visible = 0;
  double _targetVisible = 0;
  double _miss = 0;
  double _burst = -1;
  double _time = 0;

  void show() {
    _fills
      ..clear()
      ..addAll(List.filled(count, 0.0));
    _colors
      ..clear()
      ..addAll(List.filled(count, _white));
    _filled = 0;
    _burst = -1;
    _miss = 0;
    _targetVisible = 1;
  }

  void hide() => _targetVisible = 0;

  void fill(int filled, OrbType type) {
    _filled = filled.clamp(0, count);
    _colors[_filled - 1] = type.baseColor;
  }

  void miss() => _miss = 1;

  /// The dots glow for [collapseAt] seconds, then swirl into the potato
  void celebrate() => _burst = 0;

  static const collapseAt = 0.3;
  static const collapseDuration = 0.32;

  /// When the dots reach the potato
  static const collapseEnd = collapseAt + collapseDuration;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _visible += (_targetVisible - _visible) * min(1, dt * 6);
    _miss = max(0, _miss - dt * 1.6);
    for (var i = 0; i < _fills.length; i++) {
      final target = i < _filled ? 1.0 : 0.0;
      _fills[i] += (target - _fills[i]) * min(1, dt * 10);
    }
    if (_burst >= 0) {
      _burst += dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_visible < 0.01 || _fills.isEmpty) {
      return;
    }
    // When all are full: a short glow, then they swirl into the potato
    final glow = _burst < 0 ? 0.0 : _clamp01(_burst / collapseAt);
    final collapse = _burst < collapseAt
        ? 0.0
        : Curves.easeInCubic.transform(
            _clamp01((_burst - collapseAt) / collapseDuration),
          );
    final radius = _radius * (1 - collapse);
    final swirl = collapse * 1.2;
    final alpha = _visible * (collapse >= 1 ? 0.0 : 1.0);
    final burst = glow * (1 - collapse);
    final shake = _miss > 0 ? sin(_time * 70) * 6 * _miss : 0.0;
    for (var i = 0; i < count; i++) {
      final a = -pi / 2 + i * 2 * pi / count + swirl;
      final p = Offset(cos(a), sin(a)) * radius + Offset(shake, 0);
      final f = _fills[i];
      final pop = 1 + sin(_clamp01(f) * pi) * 0.9;
      final r =
          _dotRadius *
          pop *
          (0.6 + 0.4 * _visible) *
          (1 + burst * 0.8 - collapse * 0.4);
      final ring = Color.lerp(_white, _missColor, _miss)!;
      // Empty dot: a thin ring
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = ring.withValues(
            alpha: _clamp01(alpha * (0.45 + 0.5 * _miss)),
          ),
      );
      if (f > 0.01) {
        final c = _colors[i];
        canvas
          ..drawCircle(
            p,
            r * 3.2,
            Paint()
              ..blendMode = BlendMode.plus
              ..shader = ui.Gradient.radial(p, r * 3.2, [
                c.withValues(alpha: _clamp01(alpha * f * 0.7)),
                c.withValues(alpha: 0),
              ]),
          )
          ..drawCircle(
            p,
            r * f,
            Paint()
              ..color = Color.lerp(
                c,
                _white,
                0.45,
              )!.withValues(alpha: _clamp01(alpha)),
          );
      }
    }
  }
}

/// A see-through shield where the right shield should go, with arrows
/// that run from the shield toward it. It lights up when the shield is
/// in place, flashes red where the shield should have been after a hit,
/// and darkens the screen during slow motion.
class GhostShield extends PositionComponent {
  GhostShield() : super(priority: 2);

  static const _radius = 78.0;
  static const _sweep = Shield.defaultSweep;

  OrbType _type = OrbType.fire;
  double _angle = 0;

  /// Where the shield of [_type] is now, set every frame while showing
  double from = 0;

  bool locked = false;

  /// 0 normal, 1 full slow motion
  double slowMo = 0;
  double _dim = 0;

  double _visible = 0;
  double _target = 0;
  double _lock = 0;
  bool _wasLocked = false;
  double _lockAge = 1;

  /// Called when the shield reaches the ghost
  VoidCallback? onLocked;
  double _miss = 0;
  double _success = -1;
  double _time = 0;

  bool get isShowing => _target > 0;

  void showFor(
    OrbType type,
    double needFireAngle, {
    required double angleOfOrb,
  }) {
    final same = isShowing && type == _type && angleOfOrb == _angle;
    _type = type;
    _angle = angleOfOrb;
    _target = 1;
    _miss = 0;
    _success = -1;
    if (!same) {
      locked = false;
    }
  }

  /// After a hit: red, where the shield should have been
  void showMiss(
    OrbType type,
    double needFireAngle, {
    required double angleOfOrb,
  }) {
    _type = type;
    _angle = angleOfOrb;
    _target = 0;
    _visible = 1;
    _miss = 1;
    _success = -1;
  }

  void success() {
    if (_target > 0) {
      _success = 0;
    }
    _target = 0;
  }

  void hide() {
    _target = 0;
    _success = -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_miss > 0) {
      _miss = max(0, _miss - dt * 1.0);
      if (_miss == 0) {
        _visible = 0;
      }
    } else if (_success < 0) {
      _visible += (_target - _visible) * min(1, dt * 8);
    }
    if (_success >= 0) {
      _success += dt;
      if (_success > 0.45) {
        _success = -1;
        _visible = 0;
      }
    }
    if (locked != _wasLocked) {
      _wasLocked = locked;
      _lockAge = 0;
      if (locked && _target > 0) {
        onLocked?.call();
      }
    }
    _lockAge += dt;
    _lock += ((locked ? 1.0 : 0.0) - _lock) * min(1, dt * 14);
    _dim += (slowMo - _dim) * min(1, dt * 10);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_dim > 0.01) {
      // Slow motion: the world darkens around the potato
      canvas.drawCircle(
        Offset.zero,
        560,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            560,
            [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: _clamp01(_dim * 0.55)),
            ],
            [0.2, 0.8],
          ),
      );
    }
    if (_miss > 0) {
      _renderMiss(canvas);
      return;
    }
    if (_success >= 0) {
      _renderSuccess(canvas);
      return;
    }
    if (_visible < 0.01) {
      return;
    }
    final color = _type.baseColor;
    final pulse = 0.5 + 0.5 * sin(_time * 7);
    final arc = Rect.fromCircle(
      center: Offset.zero,
      radius: _radius + _lock * 3,
    );
    final start = _angle - _sweep / 2;
    // Soft wide glow
    canvas.drawArc(
      arc,
      start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 16
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = Color.lerp(color, _good, _lock * 0.7)!.withValues(
          alpha: _clamp01(_visible * (0.25 + 0.25 * pulse + 0.4 * _lock)),
        ),
    );
    // Dashed outline, solid once the shield is in place
    final dashes = 9;
    final gap = _lock > 0.5 ? 0.0 : 0.05;
    final each = _sweep / dashes;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..color = Color.lerp(Color.lerp(color, _white, 0.35)!, _good, _lock)!
          .withValues(
            alpha: _clamp01(
              _visible * (0.65 + 0.35 * (_lock > 0.5 ? 1 : pulse)),
            ),
          );
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(arc, start + i * each + gap / 2, each - gap, false, line);
    }
    if (_lock < 0.5) {
      _renderArrows(canvas, color);
    }
    _renderTick(canvas);
  }

  /// Chevrons running around the potato, on a track just outside the
  /// shields, from the shield to the ghost. Always at least three, so the
  /// way to turn is clear even when the shield is close.
  void _renderArrows(Canvas canvas, Color color) {
    var delta = (_angle - from + pi) % (2 * pi);
    if (delta < 0) {
      delta += 2 * pi;
    }
    delta -= pi;
    final span = delta.abs();
    if (span < 0.05) {
      return;
    }
    final dir = delta.sign;
    final count = max(3, (span / 0.3).round());
    final step = span / count;
    final shift = (_time * 1.4) % 1.0;
    const r = _radius + 18;
    final tint = Color.lerp(color, _white, 0.55)!;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 9
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.5;
    for (var k = 0; k <= count; k++) {
      final along = (k + shift) * step;
      if (along > span) {
        break;
      }
      final a = from + dir * along;
      // Bright in the middle of the run, never fully gone at the ends
      final fade = 0.45 + 0.55 * sin(_clamp01(along / span) * pi);
      final alpha = _clamp01(_visible * fade);
      final tip = Offset(cos(a), sin(a)) * r;
      final tangent = Offset(-sin(a), cos(a)) * dir;
      final normal = Offset(cos(a), sin(a));
      final back = tip - tangent * 10;
      final path = Path()
        ..moveTo(back.dx + normal.dx * 8, back.dy + normal.dy * 8)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(back.dx - normal.dx * 8, back.dy - normal.dy * 8);
      glow.color = color.withValues(alpha: alpha * 0.6);
      paint.color = tint.withValues(alpha: alpha);
      canvas
        ..drawPath(path, glow)
        ..drawPath(path, paint);
    }
  }

  /// A tick just outside the ghost, popping in when the shield is in place
  void _renderTick(Canvas canvas) {
    if (_lock < 0.02) {
      return;
    }
    final pop = _lockAge < 0.35 ? 1 + sin(_lockAge / 0.35 * pi) * 0.45 : 1.0;
    final size = 13.0 * _lock * pop;
    final c = Offset(cos(_angle), sin(_angle)) * (_radius + 26);
    final alpha = _clamp01(_visible * _lock);
    canvas
      ..drawCircle(
        c,
        size * 1.6,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(c, size * 1.6, [
            _good.withValues(alpha: alpha * 0.55),
            _good.withValues(alpha: 0),
          ]),
      )
      ..drawCircle(c, size, Paint()..color = _good.withValues(alpha: alpha))
      ..drawPath(
        Path()
          ..moveTo(c.dx - size * 0.45, c.dy + size * 0.02)
          ..lineTo(c.dx - size * 0.12, c.dy + size * 0.35)
          ..lineTo(c.dx + size * 0.48, c.dy - size * 0.32),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = max(1, size * 0.24)
          ..color = const Color(0xFF0B2A18).withValues(alpha: alpha),
      );
    // A ring that runs out along the ghost the moment it locks
    if (_lockAge < 0.4) {
      final t = _lockAge / 0.4;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: _radius + 4 + t * 18),
        _angle - _sweep / 2,
        _sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4 * (1 - t) + 0.5
          ..color = _good.withValues(alpha: _clamp01((1 - t) * _visible)),
      );
    }
  }

  void _renderMiss(Canvas canvas) {
    final blink = (sin(_time * 22) > 0 ? 1.0 : 0.35) * _miss;
    final arc = Rect.fromCircle(center: Offset.zero, radius: _radius);
    final start = _angle - _sweep / 2;
    canvas
      ..drawArc(
        arc,
        start,
        _sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 18
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
          ..color = _missColor.withValues(alpha: _clamp01(blink * 0.6)),
      )
      ..drawArc(
        arc,
        start,
        _sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5
          ..color = Color.lerp(
            _missColor,
            _white,
            0.3,
          )!.withValues(alpha: _clamp01(blink)),
      );
  }

  void _renderSuccess(Canvas canvas) {
    final t = _clamp01(_success / 0.45);
    final e = Curves.easeOutCubic.transform(t);
    final arc = Rect.fromCircle(center: Offset.zero, radius: _radius + e * 30);
    final sweep = _sweep * (1 + e * 0.3);
    canvas.drawArc(
      arc,
      _angle - sweep / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6 * (1 - e) + 1
        ..blendMode = BlendMode.plus
        ..color = Color.lerp(
          _type.baseColor,
          _white,
          0.6,
        )!.withValues(alpha: _clamp01(1 - t)),
    );
  }
}

/// The "you did it" moment at the end of the tutorial: a shock wave out to
/// the arena edge, confetti in fire and ice colors, and a big tick that
/// pops in over the potato, floats a moment and drifts away.
class TutorialCelebration extends PositionComponent {
  TutorialCelebration() : super(priority: 3);

  static const _confettiCount = 48;
  static const _duration = 2.4;
  static const _palette = [
    Color(0xFFFF8A3D),
    Color(0xFFFFC14D),
    Color(0xFF6FD3FF),
    Color(0xFFBDF2FF),
    _good,
    _white,
  ];

  final _rnd = Random();
  final _bits = <_Confetti>[];
  double _age = 0;

  @override
  void onMount() {
    super.onMount();
    for (var i = 0; i < _confettiCount; i++) {
      final a = _rnd.nextDouble() * 2 * pi;
      final speed = 240 + _rnd.nextDouble() * 320;
      _bits.add(
        _Confetti(
          position: Offset(cos(a), sin(a)) * (40 + _rnd.nextDouble() * 15),
          velocity: Offset(cos(a), sin(a)) * speed,
          color: _palette[i % _palette.length],
          spin: (_rnd.nextDouble() - 0.5) * 14,
          angle: _rnd.nextDouble() * pi,
          size: 4 + _rnd.nextDouble() * 4,
          life: 0.9 + _rnd.nextDouble() * 0.6,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final b in _bits) {
      b.age += dt;
      b.velocity *= pow(0.06, dt).toDouble();
      b.position += b.velocity * dt;
      b.angle += b.spin * dt;
    }
    if (_age > _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderWave(canvas);
    _renderConfetti(canvas);
    _renderTick(canvas);
  }

  void _renderWave(Canvas canvas) {
    final t = _clamp01(_age / 0.75);
    if (t >= 1) {
      return;
    }
    final e = Curves.easeOutCubic.transform(t);
    final r = ui.lerpDouble(60, ArenaRing.radius, e)!;
    canvas
      ..drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22 * (1 - t) + 2
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..color = _good.withValues(alpha: _clamp01((1 - t) * 0.55)),
      )
      ..drawCircle(
        Offset.zero,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - t) + 1
          ..color = _white.withValues(alpha: _clamp01((1 - t) * 0.9)),
      );
  }

  void _renderConfetti(Canvas canvas) {
    final paint = Paint();
    for (final b in _bits) {
      final k = b.age / b.life;
      if (k >= 1) {
        continue;
      }
      paint.color = b.color.withValues(alpha: _clamp01((1 - k) * 1.4));
      canvas
        ..save()
        ..translate(b.position.dx, b.position.dy)
        ..rotate(b.angle)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: b.size * 1.8,
              height: b.size * (0.5 + 0.5 * cos(b.angle * 2).abs()),
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  void _renderTick(Canvas canvas) {
    const popIn = 0.5;
    const leaveAt = 1.6;
    if (_age > _duration) {
      return;
    }
    final grow = Curves.elasticOut.transform(_clamp01(_age / popIn));
    final leave = Curves.easeInCubic.transform(
      _clamp01((_age - leaveAt) / (_duration - leaveAt)),
    );
    final bob = sin(_age * 5) * 3 * (1 - leave);
    final c = Offset(0, -124 - leave * 60 + bob);
    final r = 32 * grow * (1 - leave * 0.4);
    final alpha = _clamp01(1 - leave);
    if (r <= 0.5 || alpha <= 0) {
      return;
    }
    // Rays behind the badge, turning slowly
    final rays = Paint()
      ..blendMode = BlendMode.plus
      ..color = _good.withValues(alpha: alpha * 0.35);
    for (var i = 0; i < 10; i++) {
      final a = i * 2 * pi / 10 + _age * 0.8;
      final p1 = c + Offset(cos(a - 0.09), sin(a - 0.09)) * r * 1.15;
      final p2 = c + Offset(cos(a), sin(a)) * r * 2.3;
      final p3 = c + Offset(cos(a + 0.09), sin(a + 0.09)) * r * 1.15;
      canvas.drawPath(
        Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close(),
        rays,
      );
    }
    canvas
      ..drawCircle(
        c,
        r * 2,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(c, r * 2, [
            _good.withValues(alpha: alpha * 0.6),
            _good.withValues(alpha: 0),
          ]),
      )
      ..drawCircle(c, r, Paint()..color = _good.withValues(alpha: alpha))
      ..drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _white.withValues(alpha: alpha * 0.9),
      )
      ..drawPath(
        Path()
          ..moveTo(c.dx - r * 0.45, c.dy + r * 0.02)
          ..lineTo(c.dx - r * 0.12, c.dy + r * 0.36)
          ..lineTo(c.dx + r * 0.48, c.dy - r * 0.32),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = r * 0.22
          ..color = const Color(0xFF0B2A18).withValues(alpha: alpha),
      );
  }
}

class _Confetti {
  _Confetti({
    required this.position,
    required this.velocity,
    required this.color,
    required this.spin,
    required this.angle,
    required this.size,
    required this.life,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double spin;
  double angle;
  final double size;
  final double life;
  double age = 0;
}
