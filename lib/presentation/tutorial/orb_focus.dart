import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';

double _clamp01(double x) => x.clamp(0.0, 1.0);

const _white = Color(0xFFFFFFFF);
const _good = Color(0xFF6BFFA8);
const _danger = Color(0xFFFF3B4E);
const _warn = Color(0xFFFFC83D);

/// The tutorial's spotlight on the coming orb: the arena dims, with light
/// kept on the orb, its lane and the potato. The tutorial director drives
/// it with [aim], [track], [covered] and [clear].
class OrbFocus {
  OrbType type = OrbType.fire;
  double angle = 0;
  MovingOrb? _orb;

  /// The right shield is in front of the orb: the beam turns green
  bool covered = false;

  /// The orb is waiting at the shield ring for the shield to cover it
  bool held = false;

  /// [held], smoothed, drives the danger signs
  double hold = 0;

  bool _active = false;
  double visible = 0;
  double safe = 0;
  double time = 0;

  /// Last known distance of the orb from the potato's center
  double distance = startDistance;

  static const startDistance = ArenaRing.radius + 10;
  static const shieldRadius = 78.0;

  /// An orb of [type] is about to come from [angle]
  void aim(OrbType type, double angle) {
    this.type = type;
    this.angle = angle;
    _orb = null;
    _active = true;
    covered = false;
    held = false;
    distance = startDistance;
  }

  void track(MovingOrb orb) => _orb = orb;

  void clear() {
    _active = false;
    held = false;
    _orb = null;
  }

  Offset get direction => Offset(cos(angle), sin(angle));

  Offset get head => direction * distance;

  void update(double dt) {
    time += dt;
    final orb = _orb;
    if (_active && orb != null && orb.isFlying) {
      distance = orb.position.length;
    }
    visible +=
        ((_active ? 1.0 : 0.0) - visible) * min(1, dt * (_active ? 7 : 9));
    safe += ((covered && _active ? 1.0 : 0.0) - safe) * min(1, dt * 10);
    hold += ((held && _active ? 1.0 : 0.0) - hold) * min(1, dt * 8);
  }
}

/// Drawn under everything else in the arena: the dimmed arena with light
/// on the potato, the orb and the beam between them
class OrbSpotlight extends Component {
  OrbSpotlight(this.focus) : super(priority: -2);

  final OrbFocus focus;

  @override
  void update(double dt) {
    super.update(dt);
    focus.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final f = focus;
    if (f.visible < 0.01) {
      return;
    }
    // Darkest inside the arena, fading out at its edge so the view's
    // square never shows
    const reach = ArenaRing.radius + 16;
    final dim = 0.85 * f.visible;
    final bounds = Rect.fromCircle(center: Offset.zero, radius: reach);
    const shade = Color(0xFF02020E);
    canvas
      ..saveLayer(bounds, Paint())
      ..drawCircle(
        Offset.zero,
        reach,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            reach,
            [
              shade.withValues(alpha: dim),
              shade.withValues(alpha: dim),
              shade.withValues(alpha: 0),
            ],
            [0, 0.8, 1],
          ),
      );
    final cut = Paint()..blendMode = BlendMode.dstOut;
    // Light on the potato and the shields
    cut.shader = ui.Gradient.radial(
      Offset.zero,
      135,
      [_white, _white, _white.withValues(alpha: 0)],
      [0, 0.6, 1],
    );
    canvas.drawCircle(Offset.zero, 135, cut);
    // Light on the orb (or the rift before it comes through)
    final head = f.head;
    final pulse = 0.5 + 0.5 * sin(f.time * 6);
    final r = 70 + 10 * pulse;
    cut.shader = ui.Gradient.radial(head, r, [
      _white,
      _white.withValues(alpha: 0),
    ]);
    canvas.drawCircle(head, r, cut);
    // A soft beam joining them
    canvas.drawLine(
      head,
      f.direction * 60,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..strokeWidth = 64
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
        ..color = _white.withValues(alpha: 0.85),
    );
    canvas.restore();

    // A faint light in the orb's color along the beam
    final color = Color.lerp(f.type.baseColor, _good, f.safe)!;
    canvas.drawLine(
      head,
      f.direction * OrbFocus.shieldRadius,
      Paint()
        ..blendMode = BlendMode.plus
        ..strokeWidth = 46
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22)
        ..color = color.withValues(alpha: 0.3 * f.visible),
    );
  }
}

/// Drawn over everything: two rings that keep closing in on the orb (look
/// here) and, while the orb waits for the shield, danger signs: a blinking
/// warning sign beside it and a red flash on the side of the potato it
/// would hit
class OrbFocusMarks extends Component {
  OrbFocusMarks(this.focus) : super(priority: 3);

  final OrbFocus focus;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final f = focus;
    if (f.visible < 0.01) {
      return;
    }
    _rings(canvas, f);
    final danger = _clamp01(f.hold * (1 - f.safe) * f.visible);
    if (danger > 0.01) {
      _potatoFlash(canvas, f, danger);
      _sign(canvas, f, danger);
    }
  }

  void _rings(Canvas canvas, OrbFocus f) {
    final head = f.head;
    final calm = Color.lerp(f.type.baseColor, _white, 0.6)!;
    final color = Color.lerp(calm, _danger, f.hold * (1 - f.safe))!;
    // Faster while the orb waits
    final speed = 1.3 + 0.9 * f.hold;
    for (var i = 0; i < 2; i++) {
      final t = (f.time * speed + i * 0.5) % 1.0;
      final r = ui.lerpDouble(46, 16, Curves.easeInCubic.transform(t))!;
      final alpha = _clamp01(f.visible * sin(t * pi) * 0.9);
      canvas.drawCircle(
        head,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 + 1.5 * f.hold
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  void _sign(Canvas canvas, OrbFocus f, double alpha) {
    final u = f.direction;
    // Further out than the orb, so it never covers the orb or the potato
    final c = f.head + u * 46;
    final beat = sin(f.time * 10);
    final s = 16 * (0.6 + 0.4 * f.hold) * (1 + 0.1 * beat);
    final a = alpha * (beat > -0.4 ? 1.0 : 0.45);
    final tri = Path()
      ..moveTo(c.dx, c.dy - s * 1.05)
      ..lineTo(c.dx + s * 1.1, c.dy + s * 0.85)
      ..lineTo(c.dx - s * 1.1, c.dy + s * 0.85)
      ..close();
    const ink = Color(0xFF2A0A0E);
    canvas
      ..drawCircle(
        c,
        s * 2.4,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(c, s * 2.4, [
            _danger.withValues(alpha: 0.55 * a),
            _danger.withValues(alpha: 0),
          ]),
      )
      ..drawPath(tri, Paint()..color = _warn.withValues(alpha: a))
      ..drawPath(
        tri,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = s * 0.22
          ..color = _danger.withValues(alpha: a),
      )
      // The "!" mark, as shapes
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c.dx, c.dy - s * 0.05),
            width: s * 0.26,
            height: s * 0.75,
          ),
          Radius.circular(s * 0.13),
        ),
        Paint()..color = ink.withValues(alpha: a),
      )
      ..drawCircle(
        Offset(c.dx, c.dy + s * 0.55),
        s * 0.15,
        Paint()..color = ink.withValues(alpha: a),
      );
  }

  /// A red arc on the potato's side that faces the orb
  void _potatoFlash(Canvas canvas, OrbFocus f, double alpha) {
    final blink = 0.5 + 0.5 * sin(f.time * 12);
    final a = _clamp01(alpha * (0.35 + 0.65 * blink));
    final rect = Rect.fromCircle(center: Offset.zero, radius: 54);
    const sweep = 1.3;
    canvas
      ..drawArc(
        rect,
        f.angle - sweep / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 14
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
          ..color = _danger.withValues(alpha: a * 0.8),
      )
      ..drawArc(
        rect,
        f.angle - sweep / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4
          ..color = _danger.withValues(alpha: a),
      );
  }
}
