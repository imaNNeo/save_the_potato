import 'dart:math';
import 'dart:ui';

import 'package:save_the_potato/domain/hit_invincibility.dart';

import 'face_pick_stub.dart' if (dart.library.js_interop) 'face_pick_web.dart';
import 'potato_pose.dart';

/// PROTOTYPE: different faces the potato can make while it recovers from a
/// hit (the 1.6 s invincibility blink). Pick one with `?face=<name>` on web.
enum RecoveryStyle {
  /// What main does today: only the 1 s hit wince, then back to smiling.
  none,

  /// Spiral eyes, little stars circling the head, wobbly mouth, sway.
  dizzy,

  /// Eyes squeezed shut, one eye peeks, then a relieved sigh.
  relief,

  /// Worried brows, a big sweat drop sliding down, nervous tremble.
  sweat,

  /// Different for each element: fire = steam + panting tongue,
  /// ice = shivering + chattering teeth + frost.
  hotCold,

  /// Glares at where the orb came from, puffed cheeks, pout, anger mark.
  grumpy;

  static RecoveryStyle fromName(String? name) => RecoveryStyle.values
      .firstWhere((s) => s.name == name, orElse: () => RecoveryStyle.dizzy);

  /// The style picked in the URL (`?face=dizzy`), or with
  /// `--dart-define=FACE=dizzy`.
  static RecoveryStyle get selected {
    const define = String.fromEnvironment('FACE');
    if (define.isNotEmpty) return fromName(define);
    return fromName(pickedRecoveryFace());
  }
}

enum RecoveryHit { fire, ice }

/// Runs the recovery face next to [HitInvincibility].
///
/// It never touches the animator's own pose: [apply] writes into a copy, so
/// when the recovery ends the potato is exactly where its animations left it.
class RecoveryFace {
  RecoveryFace({RecoveryStyle? style})
    : _fixed = style,
      style = style ?? RecoveryStyle.selected;

  final RecoveryStyle? _fixed;
  RecoveryStyle style;
  RecoveryHit hit = RecoveryHit.fire;

  /// Angle from the potato to the orb that hit it (canvas coordinates).
  double hitAngle = 0;

  static const duration = HitInvincibility.duration;
  double _t = duration;

  bool get isActive => _t < duration && style != RecoveryStyle.none;

  /// Seconds since the hit.
  double get time => _t;

  void trigger(RecoveryHit hit, double angle) {
    // The preview page can switch faces mid-game
    style = _fixed ?? RecoveryStyle.selected;
    this.hit = hit;
    hitAngle = angle;
    _t = 0;
  }

  void reset() => _t = duration;

  void update(double dt) {
    if (_t < duration) _t = min(duration, _t + dt);
  }

  /// 0..1: eases in right after the hit and out at the end of the window.
  double get _env =>
      _smooth(0, 0.1, _t) * (1 - _smooth(duration - 0.3, duration, _t));

  // ------------------------------------------------------------ pose ----

  void apply(PotatoPose p) {
    if (!isActive) return;
    final e = _env;
    void set(PotatoProp prop, double v) => p[prop] = _lerp(p[prop], v, e);
    switch (style) {
      case RecoveryStyle.none:
        break;
      case RecoveryStyle.dizzy:
        set(PotatoProp.sparkleScaleX, 0);
        set(PotatoProp.sparkleScaleY, 0);
        set(PotatoProp.smileOpacity, 0);
        set(PotatoProp.zigzagOpacity, 0);
        set(PotatoProp.leftBrowAngle, -0.55);
        set(PotatoProp.rightBrowAngle, 0.15);
      case RecoveryStyle.relief:
        final t = _t;
        // Squeezed shut, then the left eye peeks, then both open
        final bothOpen = _smooth(0.95, 1.1, t);
        final happy = _smooth(1.1, 1.2, t) * (1 - _smooth(1.42, 1.52, t));
        // The peeking left eye is drawn in paintOver
        p[PotatoProp.eyeOpen] = _lerp(1, bothOpen * (1 - happy), e);
        set(PotatoProp.leftBrowAngle, _lerp(-0.75, -0.15, bothOpen));
        set(PotatoProp.rightBrowAngle, _lerp(0.75, 0.15, bothOpen));
        // Ouch mouth first, then a big relieved smile
        final sigh = _smooth(0.95, 1.15, t);
        set(PotatoProp.zigzagOpacity, 1 - sigh);
        set(PotatoProp.smileOpacity, sigh);
        set(PotatoProp.mouthOpacity, sigh);
        set(PotatoProp.tongueOpacity, sigh);
        set(PotatoProp.mouthY, -9.435);
        set(PotatoProp.mouthScaleX, 0.95);
        set(PotatoProp.mouthScaleY, 1);
        set(PotatoProp.smileScaleY, _lerp(1, 0.6, sigh));
        set(PotatoProp.sparkleSize, _lerp(0.5, 1, bothOpen));
      case RecoveryStyle.sweat:
        set(PotatoProp.leftBrowAngle, -0.75);
        set(PotatoProp.rightBrowAngle, 0.75);
        set(PotatoProp.sparkleScaleX, 0.55);
        set(PotatoProp.sparkleScaleY, 0.55);
        set(PotatoProp.sparkleX, sin(_t * 40) * 2.5);
        set(PotatoProp.smileOpacity, 0);
        set(PotatoProp.zigzagOpacity, 0);
        set(PotatoProp.eyeShiftY, -4);
      case RecoveryStyle.hotCold:
        if (hit == RecoveryHit.fire) {
          final squeeze = 1 - _smooth(0.6, 0.8, _t);
          p[PotatoProp.eyeOpen] = _lerp(1, 1 - squeeze, e);
          set(PotatoProp.fireTint, 0.45 * (1 - _t / duration));
          set(PotatoProp.cheekScale, 1.55);
          set(PotatoProp.leftBrowAngle, -0.6);
          set(PotatoProp.rightBrowAngle, 0.6);
          set(PotatoProp.zigzagOpacity, 0);
          set(PotatoProp.smileOpacity, 0);
        } else {
          set(PotatoProp.iceTint, 0.55 * (1 - _t / duration * 0.8));
          set(PotatoProp.leftBrowAngle, -0.7);
          set(PotatoProp.rightBrowAngle, 0.7);
          set(PotatoProp.sparkleScaleX, 0.6);
          set(PotatoProp.sparkleScaleY, 0.6);
          set(PotatoProp.cheekScale, 0.7);
          set(PotatoProp.zigzagOpacity, 0);
          set(PotatoProp.smileOpacity, 0);
        }
      case RecoveryStyle.grumpy:
        final look = Offset(cos(hitAngle), sin(hitAngle)) * 9;
        set(PotatoProp.eyeShiftX, look.dx);
        set(PotatoProp.eyeShiftY, look.dy);
        set(PotatoProp.sparkleX, look.dx * 0.6);
        set(PotatoProp.eyeOpen, 0.62);
        set(PotatoProp.leftBrowAngle, 0.42);
        set(PotatoProp.rightBrowAngle, -0.42);
        set(PotatoProp.cheekScale, 1.45);
        set(PotatoProp.smileOpacity, 0);
        set(PotatoProp.zigzagOpacity, 0);
        set(PotatoProp.frownOpacity, 1);
        set(PotatoProp.frownScaleY, 0.42);
    }
  }

  // ------------------------------------------------------- transform ----

  /// Moves the whole potato (sway, shiver). Call before painting it, in
  /// artboard coordinates.
  void transform(Canvas canvas) {
    if (!isActive) return;
    final e = _env;
    const c = Offset(242, 260);
    switch (style) {
      case RecoveryStyle.dizzy:
        canvas.translate(c.dx, c.dy + 150);
        canvas.rotate(sin(_t * 2 * pi * 1.6) * 0.09 * e);
        canvas.translate(-c.dx, -c.dy - 150);
      case RecoveryStyle.sweat:
        canvas.translate(sin(_t * 70) * 2 * e, 0);
      case RecoveryStyle.hotCold when hit == RecoveryHit.ice:
        final fade = 1 - _smooth(0.9, duration, _t) * 0.7;
        canvas.translate(sin(_t * 95) * 5 * e * fade, 0);
      case RecoveryStyle.grumpy:
        // A little "hmph" puff up at the start
        final puff = sin(min(1, _t / 0.35) * pi) * 0.06 * e;
        canvas.translate(c.dx, c.dy + 150);
        canvas.scale(1 + puff, 1 - puff * 0.6);
        canvas.translate(-c.dx, -c.dy - 150);
      default:
        break;
    }
  }

  // ---------------------------------------------------------- extras ----

  static const _ink = Color(0xFF462724);
  static const _leftEye = Offset(177.22, 240.64);
  static const _rightEye = Offset(308.38, 239.64);
  static const _mouth = Offset(243, 284);

  final _fill = Paint()..isAntiAlias = true;
  final _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Draws what the pose can't: spirals, drops, steam... in artboard
  /// coordinates, on top of the potato.
  void paintOver(Canvas canvas, PotatoPose pose) {
    if (!isActive) return;
    final e = _env;
    switch (style) {
      case RecoveryStyle.none:
        break;
      case RecoveryStyle.dizzy:
        _dizzy(canvas, e);
      case RecoveryStyle.relief:
        _relief(canvas, e);
      case RecoveryStyle.sweat:
        _sweat(canvas, e);
      case RecoveryStyle.hotCold:
        hit == RecoveryHit.fire ? _hot(canvas, e) : _cold(canvas, e);
      case RecoveryStyle.grumpy:
        _grumpy(canvas, e);
    }
  }

  void _dizzy(Canvas canvas, double e) {
    // Spiral eyes
    for (final (eye, dir) in [(_leftEye, 1.0), (_rightEye, -1.0)]) {
      final path = Path();
      const turns = 2.6;
      const steps = 60;
      final spin = _t * 2 * pi * 1.8 * dir;
      for (var i = 0; i <= steps; i++) {
        final f = i / steps;
        final a = spin + f * turns * 2 * pi * dir;
        final r = 2 + f * 24;
        final pt = eye + Offset(cos(a), sin(a)) * r;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      _stroke
        ..color = Color.fromRGBO(255, 248, 230, e)
        ..strokeWidth = 4.5;
      canvas.drawPath(path, _stroke);
    }
    // Wobbly mouth
    final mouth = Path();
    for (var i = 0; i <= 24; i++) {
      final f = i / 24;
      final x = _mouth.dx - 26 + f * 52;
      final y = _mouth.dy - 2 + sin(f * 3 * pi + _t * 9) * 6;
      i == 0 ? mouth.moveTo(x, y) : mouth.lineTo(x, y);
    }
    _stroke
      ..color = _ink.withValues(alpha: e)
      ..strokeWidth = 8;
    canvas.drawPath(mouth, _stroke);
    // Stars circling the head
    for (var i = 0; i < 3; i++) {
      final a = _t * 2 * pi * 0.9 + i * 2 * pi / 3;
      final pos = Offset(242 + cos(a) * 95, 88 + sin(a) * 20);
      final front = sin(a) > 0;
      final s = (front ? 26.0 : 19.0) * (0.6 + 0.4 * e);
      _fill.color = Color.fromRGBO(255, 214, 64, e * (front ? 1 : 0.7));
      canvas.drawPath(_star(pos, s, a * 2), _fill);
    }
  }

  void _relief(Canvas canvas, double e) {
    final t = _t;
    final leftOpen = _smooth(0.55, 0.7, t);
    final bothOpen = _smooth(0.95, 1.1, t);
    final happy = _smooth(1.1, 1.2, t) * (1 - _smooth(1.42, 1.52, t));
    _stroke
      ..color = _ink.withValues(alpha: e)
      ..strokeWidth = 9;
    // > <  squeezed eyes
    if (leftOpen < 1) {
      _chevron(canvas, _leftEye, 1, 1 - leftOpen);
    }
    // The left eye peeks open first
    final peek = leftOpen * (1 - bothOpen);
    if (peek > 0) {
      _fill.color = _ink.withValues(alpha: e * peek);
      canvas.drawOval(
        Rect.fromCenter(center: _leftEye, width: 60, height: 44 * peek),
        _fill,
      );
      _fill.color = Color.fromRGBO(255, 255, 255, e * peek);
      canvas.drawCircle(_leftEye + const Offset(-3, -3), 7 * peek, _fill);
    }
    if (bothOpen < 1) {
      _chevron(canvas, _rightEye, -1, 1 - bothOpen);
    }
    // ^ ^ content eyes during the sigh
    if (happy > 0) {
      _stroke.color = _ink.withValues(alpha: e * happy);
      for (final eye in [_leftEye, _rightEye]) {
        final arc = Path()
          ..moveTo(eye.dx - 22, eye.dy + 6)
          ..quadraticBezierTo(eye.dx, eye.dy - 22, eye.dx + 22, eye.dy + 6);
        canvas.drawPath(arc, _stroke);
      }
    }
    // Sigh puffs drifting out of the mouth
    final sigh = (t - 1.0) / 0.55;
    if (sigh > 0 && sigh < 1) {
      for (var i = 0; i < 3; i++) {
        final f = (sigh - i * 0.12).clamp(0.0, 1.0);
        if (f <= 0) continue;
        final pos = Offset(_mouth.dx + 40 + f * 70, _mouth.dy + 10 - f * 30);
        _fill.color = Color.fromRGBO(255, 255, 255, 0.85 * (1 - f) * e);
        canvas.drawCircle(pos, 9 + f * 14 - i * 2, _fill);
      }
    }
    // Tears squeezed out at the start
    final tear = 1 - _smooth(0.4, 0.6, t);
    if (tear > 0) {
      _fill.color = Color.fromRGBO(120, 200, 255, tear * e);
      for (final (eye, dir) in [(_leftEye, -1.0), (_rightEye, 1.0)]) {
        final f = min(1.0, t / 0.4);
        canvas.drawPath(
          _drop(eye + Offset(dir * (30 + f * 18), -6 + f * 10), 9),
          _fill,
        );
      }
    }
  }

  void _chevron(Canvas canvas, Offset eye, double dir, double amount) {
    final w = 20.0 * amount;
    final path = Path()
      ..moveTo(eye.dx - w * dir, eye.dy - 15)
      ..lineTo(eye.dx + w * dir, eye.dy)
      ..lineTo(eye.dx - w * dir, eye.dy + 15);
    canvas.drawPath(path, _stroke);
  }

  void _sweat(Canvas canvas, double e) {
    // Big drop sliding down the right side of the forehead
    final slide = _smooth(0.05, duration, _t);
    final pos = Offset(350, 158 + slide * 70);
    _fill.color = Color.fromRGBO(110, 196, 255, 0.95 * e);
    canvas.drawPath(_drop(pos, 30 * (0.5 + 0.5 * _smooth(0, 0.2, _t))), _fill);
    _fill.color = Color.fromRGBO(255, 255, 255, 0.9 * e);
    canvas.drawCircle(pos + const Offset(-9, 6), 6.5, _fill);
    // Little drops flying off at the hit
    final fly = _t / 0.6;
    if (fly < 1) {
      for (final (dx, dy) in [(-1.0, -1.0), (1.0, -1.2), (-1.2, -0.3)]) {
        final p = Offset(
          242 + dx * (130 + fly * 50),
          130 + dy * 40 + fly * fly * 60,
        );
        _fill.color = Color.fromRGBO(110, 196, 255, (1 - fly) * e);
        canvas.drawPath(_drop(p, 13), _fill);
      }
    }
    // Small wavy nervous mouth
    final mouth = Path();
    for (var i = 0; i <= 20; i++) {
      final f = i / 20;
      final x = _mouth.dx - 18 + f * 36;
      final y = _mouth.dy + 2 + sin(f * 4 * pi) * 4;
      i == 0 ? mouth.moveTo(x, y) : mouth.lineTo(x, y);
    }
    _stroke
      ..color = _ink.withValues(alpha: e)
      ..strokeWidth = 7;
    canvas.drawPath(mouth, _stroke);
  }

  void _hot(Canvas canvas, double e) {
    final squeeze = 1 - _smooth(0.6, 0.8, _t);
    if (squeeze > 0) {
      _stroke
        ..color = _ink.withValues(alpha: e * squeeze)
        ..strokeWidth = 9;
      _chevron(canvas, _leftEye, 1, 1);
      _chevron(canvas, _rightEye, -1, 1);
    }
    // Open panting mouth with the tongue hanging out
    final pant = 0.5 + 0.5 * sin(_t * 2 * pi * 4);
    _fill.color = _ink.withValues(alpha: e);
    canvas.drawOval(
      Rect.fromCenter(
        center: _mouth + const Offset(0, 2),
        width: 44,
        height: 26 + pant * 8,
      ),
      _fill,
    );
    _fill.color = const Color(0xFFFF786F).withValues(alpha: e);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _mouth + Offset(0, 18 + pant * 6),
          width: 24,
          height: 26,
        ),
        const Radius.circular(12),
      ),
      _fill,
    );
    // Steam rising from the head
    for (var i = 0; i < 5; i++) {
      final f = ((_t * 1.1 + i * 0.21) % 1.0);
      final x = 200 + i * 22 + sin(f * 5 + i) * 10;
      final y = 112 - f * 90;
      _fill.color = Color.fromRGBO(255, 255, 255, 0.75 * (1 - f) * e);
      canvas.drawCircle(Offset(x, y), 9 + f * 16, _fill);
    }
  }

  void _cold(Canvas canvas, double e) {
    // Chattering teeth
    final chatter = 0.5 + 0.5 * sin(_t * 2 * pi * 9);
    final h = 14 + chatter * 10;
    final rect = Rect.fromCenter(center: _mouth, width: 50, height: h);
    _fill.color = _ink.withValues(alpha: e);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(10)),
      _fill,
    );
    _fill.color = Color.fromRGBO(255, 255, 255, e);
    final top = Rect.fromLTWH(rect.left, rect.top, rect.width, 7);
    final bottom = Rect.fromLTWH(rect.left, rect.bottom - 7, rect.width, 7);
    for (final r in [top, bottom]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        _fill,
      );
    }
    _stroke
      ..color = _ink.withValues(alpha: e)
      ..strokeWidth = 2.5;
    for (var i = 1; i < 5; i++) {
      final x = rect.left + rect.width * i / 5;
      canvas.drawLine(Offset(x, top.top), Offset(x, top.bottom), _stroke);
      canvas.drawLine(Offset(x, bottom.top), Offset(x, bottom.bottom), _stroke);
    }
    // Frost cap and icicles on the head
    _fill.color = Color.fromRGBO(225, 245, 255, 0.92 * e);
    final cap = Path()
      ..moveTo(170, 132)
      ..quadraticBezierTo(244, 72, 320, 130)
      ..quadraticBezierTo(300, 128, 290, 140)
      ..quadraticBezierTo(270, 124, 250, 136)
      ..quadraticBezierTo(228, 122, 210, 138)
      ..quadraticBezierTo(195, 126, 170, 132)
      ..close();
    canvas.drawPath(cap, _fill);
    final grow = _smooth(0.1, 0.5, _t);
    for (final (x, y, l) in [
      (208.0, 136.0, 22.0),
      (250.0, 134.0, 30.0),
      (289.0, 138.0, 20.0),
    ]) {
      final icicle = Path()
        ..moveTo(x - 6, y)
        ..lineTo(x + 6, y)
        ..lineTo(x, y + l * grow)
        ..close();
      canvas.drawPath(icicle, _fill);
    }
    // Snowflakes drifting down around the potato
    _stroke
      ..color = Color.fromRGBO(255, 255, 255, 0.9 * e)
      ..strokeWidth = 3;
    for (var i = 0; i < 4; i++) {
      final f = (_t * 0.7 + i * 0.25) % 1.0;
      final c = Offset(
        [120.0, 380.0, 150.0, 360.0][i] + sin(f * 6 + i) * 8,
        120 + f * 140,
      );
      for (var k = 0; k < 3; k++) {
        final a = k * pi / 3 + _t;
        final d = Offset(cos(a), sin(a)) * 9;
        canvas.drawLine(c - d, c + d, _stroke);
      }
    }
  }

  void _grumpy(Canvas canvas, double e) {
    // Anger mark near the top right of the head, pulsing
    final pulse = 1 + 0.18 * sin(_t * 2 * pi * 3);
    final c = const Offset(352, 128);
    _stroke
      ..color = Color.fromRGBO(255, 50, 60, e)
      ..strokeWidth = 7;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(pulse * (0.4 + 0.6 * _smooth(0, 0.15, _t)));
    for (var k = 0; k < 4; k++) {
      canvas.save();
      canvas.rotate(k * pi / 2);
      final p = Path()
        ..moveTo(5, -18)
        ..quadraticBezierTo(5, -5, 18, -5);
      canvas.drawPath(p, _stroke);
      canvas.restore();
    }
    canvas.restore();
    // "Hmph" puff from the side, early on
    final f = (_t - 0.15) / 0.5;
    if (f > 0 && f < 1) {
      final side = cos(hitAngle) >= 0 ? -1.0 : 1.0;
      for (var i = 0; i < 2; i++) {
        final g = (f - i * 0.15).clamp(0.0, 1.0);
        _fill.color = Color.fromRGBO(255, 255, 255, 0.8 * (1 - g) * e);
        canvas.drawCircle(
          Offset(242 + side * (60 + g * 70), 262 + i * 8 - g * 10),
          7 + g * 10,
          _fill,
        );
      }
    }
  }

  // --------------------------------------------------------- helpers ----

  static Path _drop(Offset tip, double r) {
    // A teardrop: point on top, round at the bottom.
    return Path()
      ..moveTo(tip.dx, tip.dy - r * 1.6)
      ..cubicTo(
        tip.dx + r * 0.3,
        tip.dy - r * 0.8,
        tip.dx + r,
        tip.dy - r * 0.2,
        tip.dx + r,
        tip.dy + r * 0.4,
      )
      ..arcToPoint(
        Offset(tip.dx - r, tip.dy + r * 0.4),
        radius: Radius.circular(r),
      )
      ..cubicTo(
        tip.dx - r,
        tip.dy - r * 0.2,
        tip.dx - r * 0.3,
        tip.dy - r * 0.8,
        tip.dx,
        tip.dy - r * 1.6,
      )
      ..close();
  }

  static Path _star(Offset c, double r, double rot) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = rot - pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = c + Offset(cos(a), sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}
