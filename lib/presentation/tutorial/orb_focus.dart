import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';

import 'page_setting.dart';

double _clamp01(double x) => x.clamp(0.0, 1.0);

const _white = Color(0xFFFFFFFF);
const _good = Color(0xFF6BFFA8);
const _danger = Color(0xFFFF3B4E);
const _warn = Color(0xFFFFC83D);

/// Ways the tutorial can pull the eye to the coming orb, so we can compare
/// them. Each sample turns on some of the three looks below.
enum OrbFocusStyle {
  /// Only the ghost shield and the dots, like the shipped tutorial
  today,

  /// The arena dims, with light kept on the orb, its lane and the potato
  spotlight,

  /// A lane of arrows from the orb to the shield ring, flowing inward
  path,

  /// Warning signs: a blinking sign by the orb, a striped lane and a red
  /// flash on the side of the potato it will hit
  danger,

  /// Spotlight, path and danger signs together
  all;

  bool get hasSpotlight => this == spotlight || this == all;

  bool get hasPath => this == path || this == all;

  bool get hasDanger => this == danger || this == all;

  bool get isOn => this != today;

  /// `?orbFocus=<name>` on web, or `window.orbFocus` set by the preview
  /// page's picker. Players see [today] until one is picked.
  static OrbFocusStyle get current {
    if (!kIsWeb) {
      return today;
    }
    final name =
        Uri.base.queryParameters['orbFocus'] ?? pageSetting('orbFocus');
    for (final style in values) {
      if (style.name.toLowerCase() == name?.toLowerCase()) {
        return style;
      }
    }
    return today;
  }
}

/// What the focus looks follow: the coming orb's direction and, once it
/// flies, the orb itself. The tutorial director drives it.
class OrbFocus {
  OrbFocus(this.style);

  final OrbFocusStyle style;

  OrbType type = OrbType.fire;
  double angle = 0;
  MovingOrb? _orb;

  /// The right shield is in front of the orb: the danger turns calm green
  bool covered = false;

  bool _active = false;
  double visible = 0;
  double safe = 0;
  double time = 0;

  /// Seconds since [aim], the lane grows in from the rift during this
  double age = 0;

  /// Last known distance of the orb from the potato's center
  double distance = startDistance;

  static const startDistance = ArenaRing.radius + 10;
  static const shieldRadius = 78.0;
  static const potatoRadius = 50.0;

  /// An orb of [type] is about to come from [angle]
  void aim(OrbType type, double angle) {
    this.type = type;
    this.angle = angle;
    _orb = null;
    _active = true;
    covered = false;
    age = 0;
    distance = startDistance;
  }

  void track(MovingOrb orb) => _orb = orb;

  void clear() {
    _active = false;
    _orb = null;
  }

  /// 0 at the arena edge, 1 when the orb reaches the shields
  double get closeness =>
      _clamp01(1 - (distance - shieldRadius) / (startDistance - shieldRadius));

  Offset get direction => Offset(cos(angle), sin(angle));

  Offset get head => direction * distance;

  void update(double dt) {
    time += dt;
    age += dt;
    final orb = _orb;
    if (_active && orb != null && orb.isFlying) {
      distance = orb.position.length;
    }
    visible +=
        ((_active ? 1.0 : 0.0) - visible) * min(1, dt * (_active ? 7 : 9));
    safe += ((covered && _active ? 1.0 : 0.0) - safe) * min(1, dt * 10);
  }
}

/// Drawn under the orbs, shields and potato: the dimmed arena and the lane
class OrbFocusUnder extends Component {
  OrbFocusUnder(this.focus) : super(priority: -1);

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
    if (f.style.hasSpotlight) {
      _spotlight(canvas, f);
    }
    if (f.style.hasDanger) {
      _hazardLane(canvas, f);
    }
    if (f.style.hasPath) {
      _pathLane(canvas, f);
    }
  }

  /// How far the lane reaches in from the rift, it grows in quickly
  double _laneStart(OrbFocus f) {
    final grow = Curves.easeOutCubic.transform(_clamp01(f.age / 0.45));
    final outer = f.distance;
    return ui.lerpDouble(outer, OrbFocus.shieldRadius + 6, grow)!;
  }

  void _spotlight(Canvas canvas, OrbFocus f) {
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

  void _pathLane(Canvas canvas, OrbFocus f) {
    final u = f.direction;
    final outer = f.distance - 22;
    final inner = _laneStart(f);
    if (outer <= inner) {
      return;
    }
    final color = Color.lerp(f.type.baseColor, _good, f.safe)!;
    final tint = Color.lerp(color, _white, 0.5)!;
    // A thin guide line
    canvas.drawLine(
      u * outer,
      u * inner,
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = tint.withValues(alpha: 0.35 * f.visible),
    );
    // Chevrons flowing toward the potato
    const step = 30.0;
    final shift = (f.time * 70) % step;
    final normal = Offset(-u.dy, u.dx);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 8
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5;
    for (var d = outer - shift; d > inner; d -= step) {
      final along = _clamp01((outer - d) / max(1, outer - inner));
      final fade = 0.35 + 0.65 * sin(along * pi).abs();
      final alpha = _clamp01(f.visible * fade);
      final tip = u * (d - 7);
      final back = u * (d + 5);
      final path = Path()
        ..moveTo(back.dx + normal.dx * 9, back.dy + normal.dy * 9)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(back.dx - normal.dx * 9, back.dy - normal.dy * 9);
      glow.color = color.withValues(alpha: alpha * 0.55);
      line.color = tint.withValues(alpha: alpha);
      canvas
        ..drawPath(path, glow)
        ..drawPath(path, line);
    }
    // Where the orb meets the shield ring: a small target mark
    final at = u * (OrbFocus.shieldRadius + 2);
    final ring = 7 + 3 * sin(f.time * 8);
    canvas
      ..drawCircle(
        at,
        ring * 2.2,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(at, ring * 2.2, [
            color.withValues(alpha: 0.5 * f.visible),
            color.withValues(alpha: 0),
          ]),
      )
      ..drawCircle(
        at,
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = tint.withValues(alpha: 0.9 * f.visible),
      );
  }

  /// Caution stripes along the lane, red, flowing inward and sharper as
  /// the orb gets close
  void _hazardLane(Canvas canvas, OrbFocus f) {
    final u = f.direction;
    final outer = f.distance - 18;
    final inner = _laneStart(f);
    if (outer <= inner) {
      return;
    }
    final normal = Offset(-u.dy, u.dx);
    const half = 15.0;
    final color = Color.lerp(_danger, _good, f.safe)!;
    final blink = f.safe > 0.5
        ? 1.0
        : 0.65 + 0.35 * sin(f.time * (6 + 10 * f.closeness));
    final alpha = _clamp01(f.visible * blink);
    // Red glow on the lane
    canvas.drawLine(
      u * outer,
      u * inner,
      Paint()
        ..blendMode = BlendMode.plus
        ..strokeWidth = half * 2.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = color.withValues(alpha: 0.22 * alpha),
    );
    // The two edges
    final edge = Paint()
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.8 * alpha);
    canvas
      ..drawLine(u * outer + normal * half, u * inner + normal * half, edge)
      ..drawLine(u * outer - normal * half, u * inner - normal * half, edge);
    // Slanted stripes between them
    canvas.save();
    final clip = Path()
      ..moveTo((u * outer + normal * half).dx, (u * outer + normal * half).dy)
      ..lineTo((u * inner + normal * half).dx, (u * inner + normal * half).dy)
      ..lineTo((u * inner - normal * half).dx, (u * inner - normal * half).dy)
      ..lineTo((u * outer - normal * half).dx, (u * outer - normal * half).dy)
      ..close();
    canvas.clipPath(clip);
    const step = 20.0;
    final shift = (f.time * 45) % step;
    final stripe = Paint()
      ..strokeWidth = 7
      ..color = color.withValues(alpha: 0.5 * alpha);
    for (var d = outer + step - shift; d > inner - step; d -= step) {
      final a = u * d + normal * half;
      final b = u * (d - 14) - normal * half;
      canvas.drawLine(a, b, stripe);
    }
    canvas.restore();
  }
}

/// Drawn over everything: the warning sign by the orb and the red flash
/// on the potato's side
class OrbFocusOver extends Component {
  OrbFocusOver(this.focus) : super(priority: 3);

  final OrbFocus focus;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final f = focus;
    if (f.visible < 0.01) {
      return;
    }
    if (f.style.hasSpotlight) {
      _orbRing(canvas, f);
    }
    if (f.style.hasDanger) {
      _potatoFlash(canvas, f);
      _sign(canvas, f);
    }
  }

  /// A ring that keeps closing in on the orb: look here
  void _orbRing(Canvas canvas, OrbFocus f) {
    final head = f.head;
    final color = Color.lerp(f.type.baseColor, _white, 0.6)!;
    // Two rings, half a beat apart, shrinking onto the orb
    for (var i = 0; i < 2; i++) {
      final t = (f.time * 1.3 + i * 0.5) % 1.0;
      final r = ui.lerpDouble(46, 16, Curves.easeInCubic.transform(t))!;
      final alpha = _clamp01(f.visible * sin(t * pi) * 0.9);
      canvas.drawCircle(
        head,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  void _sign(Canvas canvas, OrbFocus f) {
    final u = f.direction;
    final side = Offset(-u.dy, u.dx);
    // Beside the orb, on the side closer to the screen's middle-top so it
    // never sits on the tail
    final c = f.head - u * 6 + side * 34;
    final pop = Curves.elasticOut.transform(_clamp01(f.age / 0.5));
    final blink = f.safe > 0.5 ? 1.0 : (sin(f.time * 10) > -0.3 ? 1.0 : 0.35);
    final s = 15 * pop * (1 + 0.12 * sin(f.time * 10));
    final alpha = _clamp01(f.visible * blink);
    if (s < 1) {
      return;
    }
    if (f.safe > 0.01) {
      // Once covered, the sign turns into a green shield tick
      _tickBadge(canvas, c, s, alpha * f.safe);
    }
    final warn = alpha * (1 - f.safe);
    if (warn < 0.01) {
      return;
    }
    final tri = Path()
      ..moveTo(c.dx, c.dy - s * 1.05)
      ..lineTo(c.dx + s * 1.1, c.dy + s * 0.85)
      ..lineTo(c.dx - s * 1.1, c.dy + s * 0.85)
      ..close();
    canvas
      ..drawCircle(
        c,
        s * 2.4,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(c, s * 2.4, [
            _danger.withValues(alpha: 0.55 * warn),
            _danger.withValues(alpha: 0),
          ]),
      )
      ..drawPath(
        tri,
        Paint()
          ..color = _warn.withValues(alpha: warn)
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        tri,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = s * 0.22
          ..color = _danger.withValues(alpha: warn),
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
        Paint()..color = const Color(0xFF2A0A0E).withValues(alpha: warn),
      )
      ..drawCircle(
        Offset(c.dx, c.dy + s * 0.55),
        s * 0.15,
        Paint()..color = const Color(0xFF2A0A0E).withValues(alpha: warn),
      );
  }

  void _tickBadge(Canvas canvas, Offset c, double s, double alpha) {
    canvas
      ..drawCircle(c, s, Paint()..color = _good.withValues(alpha: alpha))
      ..drawPath(
        Path()
          ..moveTo(c.dx - s * 0.45, c.dy + s * 0.02)
          ..lineTo(c.dx - s * 0.12, c.dy + s * 0.35)
          ..lineTo(c.dx + s * 0.48, c.dy - s * 0.32),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = s * 0.24
          ..color = const Color(0xFF0B2A18).withValues(alpha: alpha),
      );
  }

  /// A red arc on the potato's side that faces the orb, blinking faster
  /// as the orb gets closer. It fades once the shield covers it.
  void _potatoFlash(Canvas canvas, OrbFocus f) {
    final k = f.closeness;
    final blink = 0.5 + 0.5 * sin(f.time * (5 + 16 * k));
    final alpha = _clamp01(f.visible * (1 - f.safe) * (0.35 + 0.65 * blink));
    if (alpha < 0.01) {
      return;
    }
    final rect = Rect.fromCircle(
      center: Offset.zero,
      radius: OrbFocus.potatoRadius + 4,
    );
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
          ..color = _danger.withValues(alpha: alpha * 0.8),
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
          ..color = _danger.withValues(alpha: alpha),
      );
  }
}
