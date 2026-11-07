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

/// The tutorial's spotlight on the coming orb: the arena dims, with light
/// kept on the orb, its lane and the potato. The tutorial director drives
/// it with [aim], [track], [covered] and [clear].
class OrbFocus {
  OrbType type = OrbType.fire;
  double angle = 0;
  MovingOrb? _orb;

  /// The right shield is in front of the orb: the beam turns green
  bool covered = false;

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
    distance = startDistance;
  }

  void track(MovingOrb orb) => _orb = orb;

  void clear() {
    _active = false;
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

/// Two rings that keep closing in on the orb: look here
class OrbFocusRings extends Component {
  OrbFocusRings(this.focus) : super(priority: 3);

  final OrbFocus focus;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final f = focus;
    if (f.visible < 0.01) {
      return;
    }
    final head = f.head;
    final color = Color.lerp(f.type.baseColor, _white, 0.6)!;
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
}
