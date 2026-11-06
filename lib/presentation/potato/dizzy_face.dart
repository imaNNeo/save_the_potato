import 'dart:math';
import 'dart:ui';

import 'package:save_the_potato/domain/hit_invincibility.dart';

import 'potato_pose.dart';

/// The dizzy face the potato makes while it recovers from a hit.
///
/// It runs for the same time as [HitInvincibility] (the blink): spiral eyes,
/// little stars circling the head, a wobbly mouth and a slight sway. It
/// eases in right after the hit and out as the safe window ends.
///
/// It never changes the animator's own pose: [apply] writes into a copy, so
/// once it ends the potato is exactly where its animations left it.
class DizzyFace {
  static const duration = HitInvincibility.duration;

  double _t = duration;

  bool get isActive => _t < duration;

  /// Start (or restart) the dizzy face
  void trigger() => _t = 0;

  /// Stop right away, e.g. on a new run or game over
  void reset() => _t = duration;

  void update(double dt) {
    if (_t < duration) _t = min(duration, _t + dt);
  }

  /// 0..1: eases in right after the hit and out at the end of the window
  double get _strength =>
      _smooth(0, 0.1, _t) * (1 - _smooth(duration - 0.3, duration, _t));

  /// Hides what the dizzy face draws over: the sparkles and the mouth.
  void apply(PotatoPose pose) {
    if (!isActive) return;
    final e = _strength;
    void set(PotatoProp prop, double value) =>
        pose[prop] = pose[prop] + (value - pose[prop]) * e;
    set(PotatoProp.sparkleScaleX, 0);
    set(PotatoProp.sparkleScaleY, 0);
    set(PotatoProp.smileOpacity, 0);
    set(PotatoProp.zigzagOpacity, 0);
    set(PotatoProp.leftBrowAngle, -0.55);
    set(PotatoProp.rightBrowAngle, 0.15);
  }

  /// A slight sway, pivoting on the bottom of the potato. Call before
  /// painting it, in artboard coordinates.
  void transform(Canvas canvas) {
    if (!isActive) return;
    canvas.translate(_feet.dx, _feet.dy);
    canvas.rotate(sin(_t * 2 * pi * 1.6) * 0.09 * _strength);
    canvas.translate(-_feet.dx, -_feet.dy);
  }

  static const _feet = Offset(242, 410);
  static const _ink = Color(0xFF462724);
  static const _star = Color(0xFFFFD640);
  static const _leftEye = Offset(177.22, 240.64);
  static const _rightEye = Offset(308.38, 239.64);
  static const _mouth = Offset(243, 284);

  final _fill = Paint()..isAntiAlias = true;
  final _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final _path = Path();

  /// Draws the spirals, the wobbly mouth and the stars on top of the potato,
  /// in artboard coordinates.
  void paintOver(Canvas canvas) {
    if (!isActive) return;
    final e = _strength;

    // Spiral eyes, turning in opposite directions, inside the dark eyes
    _stroke
      ..color = Color.fromRGBO(255, 255, 255, e)
      ..strokeWidth = 9;
    for (final (eye, dir) in const [(_leftEye, 1.0), (_rightEye, -1.0)]) {
      const turns = 1.25;
      const steps = 40;
      final spin = _t * 2 * pi * 1.8 * dir;
      _path.reset();
      for (var i = 0; i <= steps; i++) {
        final f = i / steps;
        final a = spin + f * turns * 2 * pi * dir;
        final r = 2 + f * 19;
        final point = eye + Offset(cos(a), sin(a)) * r;
        i == 0
            ? _path.moveTo(point.dx, point.dy)
            : _path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(_path, _stroke);
    }

    // Wobbly mouth
    _path.reset();
    for (var i = 0; i <= 24; i++) {
      final f = i / 24;
      final x = _mouth.dx - 26 + f * 52;
      final y = _mouth.dy - 2 + sin(f * 3 * pi + _t * 9) * 6;
      i == 0 ? _path.moveTo(x, y) : _path.lineTo(x, y);
    }
    _stroke
      ..color = _ink.withValues(alpha: e)
      ..strokeWidth = 8;
    canvas.drawPath(_path, _stroke);

    // Stars circling the head, smaller and dimmer when behind it
    for (var i = 0; i < 3; i++) {
      final a = _t * 2 * pi * 0.9 + i * 2 * pi / 3;
      final center = Offset(242 + cos(a) * 95, 88 + sin(a) * 20);
      final front = sin(a) > 0;
      final size = (front ? 26.0 : 19.0) * (0.6 + 0.4 * e);
      _fill.color = _star.withValues(alpha: e * (front ? 1 : 0.7));
      _starPath(center, size, a * 2);
      canvas.drawPath(_path, _fill);
    }
  }

  /// A five-pointed star into [_path]
  void _starPath(Offset center, double radius, double rotation) {
    _path.reset();
    for (var i = 0; i < 10; i++) {
      final a = rotation - pi / 2 + i * pi / 5;
      final r = i.isEven ? radius : radius * 0.45;
      final point = center + Offset(cos(a), sin(a)) * r;
      i == 0
          ? _path.moveTo(point.dx, point.dy)
          : _path.lineTo(point.dx, point.dy);
    }
    _path.close();
  }

  static double _smooth(double from, double to, double x) {
    final t = ((x - from) / (to - from)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}
