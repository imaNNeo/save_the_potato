import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

/// The edge of the arena: a circle just inside the visible square. Orbs
/// come in from it, so it sits as far out as fits on every screen, and
/// everything outside it is dimmed so the cut on long screens looks meant.
class ArenaRing {
  /// Just inside the square, with room for the ring's glow
  static double get radius => GameConstants.viewSize * 0.475;
}

Vector2 _polar(double angle, double radius) =>
    Vector2(cos(angle), sin(angle)) * radius;

Offset _polarOffset(double angle, double radius) =>
    Offset(cos(angle), sin(angle)) * radius;

double _clamp01(double x) => x.clamp(0.0, 1.0);

const _white = Color(0xFFFFFFFF);
const _strokeBlur = MaskFilter.blur(BlurStyle.normal, 2.5);
const _wideBlur = MaskFilter.blur(BlurStyle.normal, 6);

/// A glowing line: a blurred wide stroke under a thin hot one
void _lightStroke(
  Canvas canvas,
  Path path,
  List<Color> c,
  double width,
  double alpha,
) {
  if (alpha <= 0 || width <= 0) {
    return;
  }
  canvas
    ..drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = c[1].withValues(alpha: _clamp01(alpha * 0.8))
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = _strokeBlur,
    )
    ..drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = Color.lerp(
          c[0],
          _white,
          0.35,
        )!.withValues(alpha: _clamp01(alpha))
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
}

void _bloom(Canvas canvas, Offset p, double radius, Color color, double a) {
  if (radius <= 0 || a <= 0) {
    return;
  }
  canvas.drawCircle(
    p,
    radius,
    Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        p,
        radius,
        [
          color.withValues(alpha: _clamp01(a)),
          color.withValues(alpha: _clamp01(a) * 0.25),
          color.withValues(alpha: 0),
        ],
        [0, 0.35, 1],
      ),
  );
}

/// The orb taking shape, like a flying orb's head
void _orbHead(Canvas canvas, Offset p, double radius, List<Color> c) {
  if (radius <= 0.2) {
    return;
  }
  _bloom(canvas, p, radius * 2.6, c[1], 0.5);
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

Path _arc(double radius, double from, double sweep) => Path()
  ..addArc(Rect.fromCircle(center: Offset.zero, radius: radius), from, sweep);

/// Draws the arena edge and dims what is outside it
class ArenaRingComponent extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState> {
  ArenaRingComponent() : super(priority: -2);

  double _time = 0;
  double _visible = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final target = bloc.state.playingState.isPlaying ? 1.0 : 0.35;
    _visible += (target - _visible) * min(1, dt * 3);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final r = ArenaRing.radius;
    // Dim everything outside the ring
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromCircle(center: Offset.zero, radius: r * 4))
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawPath(
      outside,
      Paint()..color = Color.fromRGBO(0, 0, 0, 0.45 * _visible),
    );
    // A soft inner glow and a thin line
    final breathe = 0.85 + 0.15 * sin(_time * 1.3);
    canvas
      ..drawCircle(
        Offset.zero,
        r - 3,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Color.fromRGBO(140, 170, 255, 0.07 * _visible * breathe)
          ..maskFilter = _wideBlur,
      )
      ..drawCircle(
        Offset.zero,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Color.fromRGBO(200, 215, 255, 0.22 * _visible * breathe),
      );
  }
}

/// A tear opens in the arena ring, bulges inward, and the orb comes
/// through it. It takes almost no room, so the orb starts at the ring.
class RingRift extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState> {
  RingRift({
    required this.type,
    required this.spawnAngle,
    required this.formDuration,
  }) : super(priority: 0);

  final OrbType type;
  final double spawnAngle;
  final double formDuration;

  static const _closeDuration = 0.35;

  /// How long every rift shows before it throws. It is the same for all
  /// rifts at a given moment, and shrinks evenly from [maxFormDuration] to
  /// [minFormDuration] as the difficulty rises, so the player is never
  /// tricked.
  static double formDurationFor(double difficulty) =>
      maxFormDuration -
      (maxFormDuration - minFormDuration) * difficulty.clamp(0.0, 1.0);

  /// At the start of a run
  static const maxFormDuration = 0.5;

  /// At full difficulty
  static const minFormDuration = 0.4;

  double _form = 0;
  double? _closing;
  double _time = 0;

  double get _radius => ArenaRing.radius;

  /// Where the orb leaves from, in world space (the potato is at 0, 0)
  Vector2 get spawnPoint => _polar(spawnAngle, _radius - 4);

  /// The orb has left: the tear snaps shut and goes away
  void close() => _closing ??= 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (!bloc.state.playingState.isPlaying) {
      close();
    }
    if (_closing != null) {
      _closing = _closing! + dt / _closeDuration;
      if (_closing! >= 1) {
        removeFromParent();
      }
      return;
    }
    _form = min(1, _form + dt / formDuration);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    paint(
      canvas,
      type: type,
      spawnAngle: spawnAngle,
      form: _form,
      closing: _closing ?? 0,
      time: _time,
    );
  }

  /// Draws a rift at [spawnAngle] on the ring. [form] goes 0 to 1 while it
  /// opens, [closing] 0 to 1 after the orb has left.
  static void paint(
    Canvas canvas, {
    required OrbType type,
    required double spawnAngle,
    required double form,
    required double closing,
    required double time,
  }) {
    final c = type.colors;
    final r = ArenaRing.radius;
    final open = Curves.easeOutCubic.transform(form) * (1 - closing);
    // How far along the ring the tear reaches, each side
    final half = 0.05 + 0.17 * open;
    // How deep it bulges inward in the middle
    final depth = 4 + 16 * Curves.easeIn.transform(form) * (1 - closing);
    const steps = 18;
    final inner = Path();
    final outer = Path();
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final a = spawnAngle - half + 2 * half * k;
      final bump = sin(k * pi);
      final flicker = 1 + 0.12 * sin(time * 30 + k * 9);
      final pIn = _polarOffset(a, r - depth * bump * flicker);
      final pOut = _polarOffset(a, r + 3 * bump);
      if (i == 0) {
        inner.moveTo(pIn.dx, pIn.dy);
        outer.moveTo(pOut.dx, pOut.dy);
      } else {
        inner.lineTo(pIn.dx, pIn.dy);
        outer.lineTo(pOut.dx, pOut.dy);
      }
    }
    final life = _clamp01(form * 4) * (1 - closing);
    // The light leaking through the tear
    final mid = _polarOffset(spawnAngle, r - depth * 0.5);
    _bloom(canvas, mid, 26 + 18 * open, c[1], 0.35 * life);
    // The ring around the tear heats up
    _lightStroke(
      canvas,
      _arc(r, spawnAngle - half * 1.8, half * 3.6),
      c,
      1.0,
      0.35 * life,
    );
    _lightStroke(canvas, outer, c, 1.6, 0.8 * life);
    _lightStroke(canvas, inner, c, 2.2, life);
    // The orb pushing through near the end
    final grow = Curves.easeOutBack.transform(_clamp01((form - 0.65) / 0.35));
    _orbHead(
      canvas,
      _polarOffset(spawnAngle, r - 4),
      10 * grow * (1 - closing),
      c,
    );
    // The snap when it lets go
    if (closing > 0) {
      final fade = 1 - closing;
      _bloom(
        canvas,
        _polarOffset(spawnAngle, r - 4),
        14 + 20 * closing,
        _white,
        0.8 * fade * fade,
      );
      _lightStroke(
        canvas,
        _arc(r, spawnAngle - 0.25 - 0.3 * closing, 0.5 + 0.6 * closing),
        c,
        2 * fade,
        fade,
      );
    }
  }
}
