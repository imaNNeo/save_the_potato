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

/// A ring of dots around the potato, one for each orb the player has to
/// block. Each block fills one, a hit shakes them red, and when all are
/// full they burst out to the arena edge as the real game starts.
class TutorialProgressDots extends PositionComponent {
  TutorialProgressDots({required this.count}) : super(priority: 2);

  final int count;

  static const _radius = 104.0;
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

  void celebrate() => _burst = 0;

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
    final burst = _burst < 0
        ? 0.0
        : Curves.easeOutCubic.transform(_clamp01(_burst / 0.9));
    final radius = ui.lerpDouble(_radius, ArenaRing.radius, burst)!;
    final alpha = _visible * (1 - burst);
    final shake = _miss > 0 ? sin(_time * 70) * 6 * _miss : 0.0;
    for (var i = 0; i < count; i++) {
      final a = -pi / 2 + i * 2 * pi / count;
      final p = Offset(cos(a), sin(a)) * radius + Offset(shake, 0);
      final f = _fills[i];
      final pop = 1 + sin(_clamp01(f) * pi) * 0.9;
      final r = _dotRadius * pop * (0.6 + 0.4 * _visible) * (1 + burst * 2);
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
    if (burst > 0) {
      // The ring of light the dots leave as they fly out
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - burst) + 0.5
          ..color = _white.withValues(alpha: _clamp01((1 - burst) * 0.6)),
      );
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
  double _miss = 0;
  double _success = -1;
  double _time = 0;

  bool get isShowing => _target > 0;

  void showFor(
    OrbType type,
    double needFireAngle, {
    required double angleOfOrb,
  }) {
    _type = type;
    _angle = angleOfOrb;
    _target = 1;
    _miss = 0;
    _success = -1;
    locked = false;
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
    _lock += ((locked ? 1.0 : 0.0) - _lock) * min(1, dt * 12);
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
        ..color = Color.lerp(color, _white, _lock * 0.5)!.withValues(
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
      ..color = Color.lerp(
        color,
        _white,
        0.35 + _lock * 0.5,
      )!.withValues(alpha: _clamp01(_visible * (0.65 + 0.35 * pulse)));
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(arc, start + i * each + gap / 2, each - gap, false, line);
    }
    if (_lock < 0.5) {
      _renderArrows(canvas, color);
    }
  }

  /// Small chevrons running around the potato from the shield to the ghost
  void _renderArrows(Canvas canvas, Color color) {
    var delta = (_angle - from + pi) % (2 * pi);
    if (delta < 0) {
      delta += 2 * pi;
    }
    delta -= pi;
    final span = delta.abs() - _sweep / 2;
    if (span < 0.15) {
      return;
    }
    final dir = delta.sign;
    const step = 0.32;
    final shift = (_time * 1.6) % 1.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3;
    const r = _radius + 16;
    for (var k = 0.0; k < span / step; k++) {
      final along = (k + shift) * step;
      if (along > span) {
        break;
      }
      final a = from + dir * along;
      final fade = sin(_clamp01(along / span) * pi);
      paint.color = Color.lerp(
        color,
        _white,
        0.5,
      )!.withValues(alpha: _clamp01(_visible * fade * 0.9));
      final tip = Offset(cos(a), sin(a)) * r;
      final tangent = Offset(-sin(a), cos(a)) * dir;
      final normal = Offset(cos(a), sin(a));
      final back = tip - tangent * 7;
      canvas.drawPath(
        Path()
          ..moveTo(back.dx + normal.dx * 5, back.dy + normal.dy * 5)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(back.dx - normal.dx * 5, back.dy - normal.dy * 5),
        paint,
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
