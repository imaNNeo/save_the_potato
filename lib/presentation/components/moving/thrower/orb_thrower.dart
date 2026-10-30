import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

/// The candidate looks of the enemies that throw the orbs.
///
/// While we pick one, the web build reads it from `?look=` in the page URL.
enum ThrowerLook {
  wisp,
  imp,
  watcher,
  golem;

  static ThrowerLook get current {
    final name = Uri.base.queryParameters['look'];
    return ThrowerLook.values.firstWhere(
      (look) => look.name == name,
      orElse: () => ThrowerLook.wisp,
    );
  }
}

/// An enemy sitting on a ring around the potato. It winds up, throws an orb
/// of its own [type], then glides to another spot. During the waves it turns
/// angry.
class OrbThrower extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState> {
  OrbThrower({
    required this.type,
    required this.look,
    required double ringAngle,
    this.ringRadius = 250,
    this.radius = 21,
  }) : _angle = ringAngle,
       _seed = type.isFire ? 0 : 2,
       super(anchor: Anchor.center, priority: 2) {
    _placeOnRing();
  }

  final OrbType type;
  final ThrowerLook look;
  final double ringRadius;
  final double radius;
  final double _seed;

  double _angle;
  double get ringAngle => _angle;

  double _time = 0;

  // Gliding between two spots on the ring
  double _fromAngle = 0, _toAngle = 0, _moveT = 1, _moveDuration = 1;
  bool get isMoving => _moveT < 1;

  // Wind-up before a throw
  double _windup = 0, _windupDuration = 0;
  void Function(Vector2 releasePosition)? _onRelease;
  bool get isWindingUp => _onRelease != null;
  double get _charge =>
      isWindingUp ? 1 - (_windup / _windupDuration).clamp(0.0, 1.0) : 0;

  double _recoil = 0;

  /// 0 is calm, 1 is angry, it eases between the two
  double _mood = 0;
  bool angry = false;

  /// Fades in when playing, out on game over
  double _opacity = 0;

  final _facing = Vector2(1, 0);

  Vector2 get releasePosition => position + _facing * (radius * 1.5);

  void _placeOnRing() {
    position.setValues(cos(_angle) * ringRadius, sin(_angle) * ringRadius);
    _facing
      ..setFrom(-position)
      ..normalize();
  }

  /// Glides along the ring to [angle] (the short way round)
  void moveTo(double angle, {double duration = 0.8}) {
    final diff = atan2(sin(angle - _angle), cos(angle - _angle));
    _fromAngle = _angle;
    _toAngle = _angle + diff;
    _moveDuration = duration;
    _moveT = 0;
  }

  /// Charges for [duration] seconds, then calls [onRelease] with the spot the
  /// orb leaves from.
  void windUpAndThrow(
    double duration,
    void Function(Vector2 releasePosition) onRelease,
  ) {
    _release();
    _moveT = 1;
    _windupDuration = max(duration, 0.01);
    _windup = _windupDuration;
    _onRelease = onRelease;
  }

  /// A throw with no wind-up, used when it spits out a fast series
  void kick() => _recoil = 1;

  void _release() {
    final onRelease = _onRelease;
    if (onRelease == null) {
      return;
    }
    _onRelease = null;
    _recoil = 1;
    onRelease(releasePosition);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final playing = bloc.state.playingState.isPlaying;
    _opacity = (_opacity + (playing ? dt * 2 : -dt * 3)).clamp(0.0, 1.0);
    if (!playing) {
      _onRelease = null;
    }
    final moodTarget = angry ? 1.0 : 0.0;
    _mood += (moodTarget - _mood).clamp(-dt * 2, dt * 2);
    _recoil = max(0, _recoil - dt * 5);

    if (_moveT < 1) {
      _moveT = min(1, _moveT + dt / _moveDuration);
      final t = Curves.easeInOutCubic.transform(_moveT);
      _angle = ui.lerpDouble(_fromAngle, _toAngle, t)!;
      _placeOnRing();
    }
    if (isWindingUp) {
      _windup -= dt;
      if (_windup <= 0) {
        _release();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_opacity <= 0) {
      return;
    }
    final charge = _charge;
    // Leans back while charging, jolts forward on release
    final lean = -0.25 * charge + 0.3 * _recoil;
    final f = Offset(_facing.x, _facing.y);
    final center = f * (radius * lean);
    canvas.saveLayer(
      null,
      Paint()..color = Color.fromRGBO(255, 255, 255, _opacity),
    );
    final painter = _ThrowerPainter(
      canvas: canvas,
      type: type,
      r: radius,
      f: f,
      t: _time,
      m: _mood,
      charge: charge,
      seed: _seed,
    );
    switch (look) {
      case ThrowerLook.wisp:
        painter.wisp(center);
      case ThrowerLook.imp:
        painter.imp(center);
      case ThrowerLook.watcher:
        painter.watcher(center);
      case ThrowerLook.golem:
        painter.golem(center);
    }
    if (charge > 0) {
      painter.forming(f * (radius * 1.5), 8.5 * charge);
    }
    canvas.restore();
  }
}

/// Draws one thrower around the origin. [f] points at the potato, [m] is the
/// mood (0 calm, 1 angry), [charge] goes 0 to 1 during the wind-up.
class _ThrowerPainter {
  _ThrowerPainter({
    required this.canvas,
    required this.type,
    required this.r,
    required this.f,
    required this.t,
    required this.m,
    required this.charge,
    required this.seed,
  }) : c = _colors(type, m);

  final Canvas canvas;
  final OrbType type;
  final double r, t, m, charge, seed;
  final Offset f;
  final List<Color> c;

  static const _angryFire = [
    Color(0xFFFFD08A),
    Color(0xFFFF2F00),
    Color(0xFFB80F00),
  ];
  static const _angryIce = [
    Color(0xFFE4F6FF),
    Color(0xFF2F7BFF),
    Color(0xFF3A2DD8),
  ];
  static const _ink = Color(0xFF0B0F24);
  static const _white = Color(0xFFFFFFFF);

  static List<Color> _colors(OrbType type, double m) {
    final angry = type.isFire ? _angryFire : _angryIce;
    return [
      for (var i = 0; i < 3; i++) Color.lerp(type.colors[i], angry[i], m)!,
    ];
  }

  Color get _brow => Color.lerp(c[2], const Color(0xFF000000), 0.65)!;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _glow(Offset p, double radius, Color color, double alpha) {
    canvas.drawCircle(
      p,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(p, radius, [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ]),
    );
  }

  /// The orb taking shape in front of it while it winds up
  void forming(Offset p, double radius) {
    _glow(p, radius * 2.4, c[1], 0.35);
    canvas.drawCircle(
      p,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          p,
          radius,
          [
            Color.lerp(c[0], _white, 0.5)!,
            c[0],
            c[1],
            c[2],
            c[2].withValues(alpha: 0),
          ],
          [0, 0.28, 0.58, 0.82, 1],
        ),
    );
  }

  /// A cute dark eye with a sparkle. Angry squints it and adds a brow,
  /// [side] tilts the brow toward the middle.
  void _eye(Offset p, double s, int side) {
    final h = s * _lerp(1.15, 0.62, m);
    canvas.drawOval(
      Rect.fromCenter(
        center: p + f * (s * 0.18),
        width: s * 1.56,
        height: h * 2,
      ),
      Paint()..color = _ink,
    );
    final sparkle = Paint()..color = _white.withValues(alpha: 0.95);
    canvas
      ..drawCircle(
        p + f * (s * 0.3) + Offset(-s * 0.22, -h * 0.35),
        s * 0.28,
        sparkle,
      )
      ..drawCircle(
        p + f * (s * 0.3) + Offset(s * 0.2, h * 0.25),
        s * 0.12,
        sparkle,
      );
    if (m > 0.02) {
      final tilt = side * s * 0.75;
      final brow = Path()
        ..moveTo(p.dx - s * 1.15, p.dy - h - s * 0.15 - tilt * 0.5)
        ..lineTo(p.dx + s * 1.15, p.dy - h - s * 0.15 + tilt * 0.5)
        ..lineTo(p.dx + s * 1.15, p.dy - h - s * 0.9 + tilt * 0.5)
        ..lineTo(p.dx - s * 1.15, p.dy - h - s * 0.9 - tilt * 0.5)
        ..close();
      canvas.drawPath(brow, Paint()..color = _brow.withValues(alpha: m));
    }
  }

  void _eyes(Offset center, double dx, double dy, double s) {
    final look = Offset(f.dx * r * 0.12, f.dy * r * 0.1);
    _eye(center + Offset(-dx, dy) + look, s, 1);
    _eye(center + Offset(dx, dy) + look, s, -1);
  }

  /// A small smile, or gritted teeth when angry
  void _mouth(Offset p, double w) {
    if (m < 0.5) {
      canvas.drawArc(
        Rect.fromCircle(center: p + Offset(0, -w * 0.35), radius: w * 0.5),
        pi * 0.2,
        pi * 0.6,
        false,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.22
          ..strokeCap = StrokeCap.round,
      );
      return;
    }
    canvas.drawOval(
      Rect.fromCenter(center: p, width: w * 1.4, height: w * 0.64),
      Paint()..color = _ink,
    );
    final teeth = Path()..moveTo(p.dx - w * 0.55, p.dy + w * 0.12);
    for (var i = 1; i <= 6; i++) {
      teeth.lineTo(
        p.dx - w * 0.55 + i * w * 0.183,
        p.dy + (i.isOdd ? -1 : 1) * w * 0.12,
      );
    }
    canvas.drawPath(
      teeth,
      Paint()
        ..color = _white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.1
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// A: a little spirit with a flickering tail
  void wisp(Offset o) {
    _glow(o, r * (2.4 + m * 0.6), c[1], 0.32 + 0.15 * m);
    final back = -f;
    final perp = Offset(-back.dy, back.dx);
    final speed = _lerp(5, 11, m), amp = r * _lerp(0.25, 0.5, m);
    final length = r * _lerp(1.7, 2.1, m);
    for (var i = 12; i >= 1; i--) {
      final k = i / 12;
      final wave = sin(t * speed + seed - k * 3.2) * amp * k;
      final p = o + back * (length * k) + perp * wave;
      final pr = r * (1.05 - k * 0.85);
      canvas.drawCircle(
        p,
        pr,
        Paint()
          ..shader = ui.Gradient.radial(p, pr, [
            c[1].withValues(alpha: 0.9),
            c[2].withValues(alpha: 0),
          ]),
      );
    }
    final squash = 1 - 0.14 * charge;
    canvas
      ..save()
      ..translate(o.dx, o.dy)
      ..rotate(atan2(f.dy, f.dx))
      ..scale(squash, 1 / squash)
      ..drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            r,
            [
              Color.lerp(c[0], _white, 0.5)!,
              c[0],
              c[1],
              c[2].withValues(alpha: 0.85),
            ],
            [0, 0.45, 0.8, 1],
            TileMode.clamp,
            null,
            Offset(r * 0.15, 0),
          ),
      )
      ..restore();
    final bob = sin(t * 2 + seed) * r * 0.04;
    _eyes(o, r * 0.36, -r * 0.08 + bob, r * 0.2);
    _mouth(
      o + Offset(f.dx * r * 0.12, r * 0.38 + f.dy * r * 0.1 + bob),
      r * 0.32,
    );
  }

  /// B: a round face ringed with flame tongues or ice shards
  void imp(Offset o) {
    _glow(o, r * (2.3 + m * 0.7), c[1], 0.3 + 0.15 * m);
    final n = m > 0.5 ? 12 : 8;
    final spin = t * _lerp(0.5, 2.6, m) + seed;
    final len = r * _lerp(0.55, 1.15, m) * (1 + 0.15 * charge);
    final half = (pi / n) * 0.75;
    for (var i = 0; i < n; i++) {
      final a = spin + i * pi * 2 / n;
      final flick = type.isFire ? 0.75 + 0.25 * sin(t * 9 + i * 1.7 + seed) : 1;
      final l = len * flick;
      final ca = cos(a), sa = sin(a);
      final base = o + Offset(cos(a - half), sin(a - half)) * (r * 0.85);
      final tip = o + Offset(ca, sa) * (r + l);
      final path = Path()..moveTo(base.dx, base.dy);
      if (type.isFire) {
        final curl = Offset(-sa, ca) * (r * 0.25);
        final ctrl = o + Offset(ca, sa) * (r + l * 0.4) - curl * 0.8;
        path.quadraticBezierTo(
          ctrl.dx,
          ctrl.dy,
          tip.dx + curl.dx,
          tip.dy + curl.dy,
        );
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      final end = o + Offset(cos(a + half), sin(a + half)) * (r * 0.85);
      path
        ..lineTo(end.dx, end.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(o + Offset(ca, sa) * (r * 0.8), tip, [
            c[1],
            (type.isFire ? c[0] : _white).withValues(alpha: 0.9),
          ]),
      );
    }
    canvas.drawCircle(
      o,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          o,
          r,
          [Color.lerp(c[0], _white, 0.5)!, c[0], c[1]],
          [0, 0.6, 1],
          TileMode.clamp,
          null,
          o + Offset(-r * 0.2, -r * 0.25),
        ),
    );
    _eyes(o, r * 0.34, -r * 0.1, r * 0.19);
    final mouthAt = o + Offset(f.dx * r * 0.12, r * 0.38 + f.dy * r * 0.1);
    if (m < 0.5) {
      _mouth(mouthAt, r * 0.3);
      return;
    }
    final w = r * 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(mouthAt.dx - w, mouthAt.dy - w * 0.2)
        ..quadraticBezierTo(
          mouthAt.dx,
          mouthAt.dy + w * 0.9,
          mouthAt.dx + w,
          mouthAt.dy - w * 0.2,
        )
        ..close(),
      Paint()..color = _ink,
    );
    for (var i = 0; i < 4; i++) {
      final x = mouthAt.dx - w * 0.75 + i * w * 0.5;
      canvas.drawPath(
        Path()
          ..moveTo(x - w * 0.16, mouthAt.dy - w * 0.12)
          ..lineTo(x + w * 0.16, mouthAt.dy - w * 0.12)
          ..lineTo(x, mouthAt.dy + w * 0.18)
          ..close(),
        Paint()..color = _white,
      );
    }
  }

  /// C: a portal ring with one eye inside
  void watcher(Offset o) {
    _glow(
      o,
      r * (2.2 + m * 0.6 + charge * 0.4),
      c[1],
      0.3 + 0.2 * m + 0.15 * charge,
    );
    canvas.drawCircle(
      o,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          o,
          r,
          [
            const Color(0xFF050A1F),
            const Color(0xFF081033),
            c[2].withValues(alpha: 0.9),
          ],
          [0, 0.75, 1],
        ),
    );
    final open = m > 0.5 ? 1.0 : _lerp(0.42, 1, m * 2);
    final blink = (m < 0.5 && ((t + seed) % 4.2) < 0.14) ? 0.08 : 1.0;
    final eh = max(r * 0.55 * open * blink * (1 + 0.15 * charge), 0.5);
    final ew = r * 0.72;
    final eyeRect = Rect.fromCenter(center: o, width: ew * 2, height: eh * 2);
    canvas
      ..save()
      ..clipPath(Path()..addOval(eyeRect))
      ..drawRect(eyeRect, Paint()..color = const Color(0xFFF2F6FF));
    final iris = o + Offset(f.dx * ew * 0.35, f.dy * eh * 0.4);
    final ir = r * _lerp(0.36, 0.27, m);
    canvas
      ..drawCircle(
        iris,
        ir,
        Paint()
          ..shader = ui.Gradient.radial(
            iris,
            ir,
            [c[0], c[1], c[2]],
            [0, 0.7, 1],
          ),
      )
      ..drawOval(
        Rect.fromCenter(
          center: iris,
          width: ir * _lerp(0.42, 0.14, m) * 2,
          height: ir * _lerp(0.42, 0.8, m) * 2,
        ),
        Paint()..color = const Color(0xFF05070F),
      )
      ..drawCircle(
        iris + Offset(-ir * 0.35, -ir * 0.35),
        ir * 0.18,
        Paint()..color = _white.withValues(alpha: 0.9),
      )
      ..restore()
      ..drawOval(
        eyeRect,
        Paint()
          ..color = c[2].withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06,
      );
    final spin = t * _lerp(0.6, 3.5, m) + seed;
    final ring = Rect.fromCircle(center: o, radius: r * 1.08);
    for (var i = 0; i < 3; i++) {
      final a0 = spin + i * pi * 2 / 3;
      canvas
        ..drawArc(
          ring,
          a0,
          pi * 2 / 3 - 0.45,
          false,
          Paint()
            ..color = c[1].withValues(alpha: 0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.22
            ..strokeCap = StrokeCap.round,
        )
        ..drawArc(
          ring,
          a0 + 0.1,
          pi * 2 / 3 - 0.65,
          false,
          Paint()
            ..color = c[0].withValues(alpha: 0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.07
            ..strokeCap = StrokeCap.round,
        );
    }
    if (m > 0.3) {
      for (var i = 0; i < 5; i++) {
        final life = (t * 2 + i * 0.37) % 1;
        final a = -spin * 1.3 + i * 1.256;
        final d = r * (1.35 + life * 0.7);
        canvas.drawCircle(
          o + Offset(cos(a), sin(a)) * d,
          r * 0.07,
          Paint()..color = c[0].withValues(alpha: m * (1 - life)),
        );
      }
    }
  }

  /// D: a cracked lava rock (fire) or a crystal (ice) with orbiting shards
  void golem(Offset o) {
    o += Offset(0, sin(t * 1.8 + seed) * r * 0.08);
    _glow(o, r * (2.2 + m * 0.6), c[1], 0.25 + 0.2 * m);
    final spin = t * _lerp(0.8, 3.2, m) + seed;
    final orbit = r * _lerp(1.65, 1.35, m);
    final facing = atan2(f.dy, f.dx);
    for (var i = 0; i < 3; i++) {
      final a = spin + i * pi * 2 / 3;
      final p = o + Offset(cos(a) * orbit, sin(a) * orbit * 0.75);
      final s = r * 0.38;
      final shard = Path()
        ..moveTo(s, 0)
        ..lineTo(0, s * 0.45)
        ..lineTo(-s * 0.7, 0)
        ..lineTo(0, -s * 0.45)
        ..close();
      canvas
        ..save()
        ..translate(p.dx, p.dy)
        ..rotate(_lerp(a + pi / 2, facing, m))
        ..drawPath(
          shard,
          Paint()
            ..color = type.isFire
                ? const Color(0xFF2A1712)
                : c[0].withValues(alpha: 0.95),
        )
        ..drawPath(
          shard,
          Paint()
            ..color = c[1].withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.12,
        )
        ..restore();
    }
    final points = type.isIce
        ? const [
            Offset(0, -1.25),
            Offset(0.82, -0.35),
            Offset(0.62, 0.75),
            Offset(0, 1.15),
            Offset(-0.62, 0.75),
            Offset(-0.82, -0.35),
          ]
        : const [
            Offset(0, -1.1),
            Offset(0.7, -0.85),
            Offset(1.0, -0.15),
            Offset(0.8, 0.7),
            Offset(0.15, 1.05),
            Offset(-0.6, 0.85),
            Offset(-1.0, 0.2),
            Offset(-0.8, -0.65),
          ];
    final body = Path()..addPolygon([for (final p in points) o + p * r], true);
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          o + Offset(-r, -r),
          o + Offset(r, r),
          type.isIce
              ? [const Color(0xFFEBF8FF), c[0], c[2]]
              : [
                  const Color(0xFF4A2B22),
                  const Color(0xFF301A14),
                  const Color(0xFF170B08),
                ],
        ),
    );
    canvas
      ..drawPath(
        body,
        Paint()
          ..color = c[1].withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06,
      )
      ..save()
      ..clipPath(body);
    final heat =
        _lerp(0.45, 1, m) * (0.85 + 0.15 * sin(t * 6 + seed)) + charge * 0.3;
    final cracks = Path();
    void line(List<Offset> pts) {
      cracks.moveTo(o.dx + pts.first.dx * r, o.dy + pts.first.dy * r);
      for (final p in pts.skip(1)) {
        cracks.lineTo(o.dx + p.dx * r, o.dy + p.dy * r);
      }
    }

    if (type.isFire) {
      line(const [Offset(-0.7, 0.7), Offset(-0.2, 0.45), Offset(0, 0.95)]);
      line(const [Offset(0.9, 0.2), Offset(0.45, 0.5), Offset(0.55, 0.85)]);
      line(const [Offset(-0.2, -1.0), Offset(0, -0.7)]);
      final crackPaint = Paint()
        ..color = c[0].withValues(alpha: heat.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * _lerp(0.07, 0.12, m)
        ..strokeJoin = StrokeJoin.round;
      canvas
        ..drawPath(
          cracks,
          Paint()
            ..color = c[1].withValues(alpha: heat.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.3
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15),
        )
        ..drawPath(cracks, crackPaint);
    } else {
      line(const [Offset(0, -1.25), Offset(0, 1.15)]);
      line(const [Offset(-0.82, -0.35), Offset(0.62, 0.75)]);
      canvas.drawPath(
        cracks,
        Paint()
          ..color = _white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.04,
      );
    }
    canvas.restore();
    final slit = _lerp(0.12, 0.07, m);
    for (final s in const [-1, 1]) {
      final p = o + Offset(s * r * 0.3 + f.dx * r * 0.1, -r * 0.15);
      canvas
        ..save()
        ..translate(p.dx, p.dy)
        ..rotate(s * _lerp(0.1, -0.45, m))
        ..drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 0.6,
            height: r * slit * 3,
          ),
          Paint()
            ..color = c[0]
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15),
        )
        ..drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 0.4,
            height: r * slit * 2,
          ),
          Paint()..color = type.isFire ? c[0] : const Color(0xFF0B1A4A),
        )
        ..restore();
    }
  }
}
