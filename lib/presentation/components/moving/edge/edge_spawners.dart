import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'orb_telegraph.dart';

/// How the player is shown where the next orb comes from
enum SpawnStyle {
  /// A white hole forms somewhere inside the square (today)
  portal,

  /// A tear opens in the arena ring and the orb comes through it
  ringRift,

  /// A fire and an ice spawner crawl along the arena ring
  rimCrawler,

  /// A ripple runs out from the potato to the ring, then the orb comes back
  ripple;

  bool get usesRing => this != portal;

  /// On web, `?spawn=ringRift` (etc.) picks one for comparing
  static final SpawnStyle current = () {
    if (!kIsWeb) {
      return SpawnStyle.portal;
    }
    final name = Uri.base.queryParameters['spawn'];
    return SpawnStyle.values.firstWhere(
      (s) => s.name == name,
      orElse: () => SpawnStyle.portal,
    );
  }();
}

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

/// Idea 1: a tear opens in the arena ring, bulges inward, and the orb comes
/// through it. It takes almost no room, so the orb starts at the ring.
class RingRift extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState>
    implements OrbTelegraph {
  RingRift({
    required this.type,
    required this.spawnAngle,
    required this.formDuration,
  }) : super(priority: 0);

  final OrbType type;
  final double spawnAngle;
  final double formDuration;

  static const _closeDuration = 0.35;

  double _form = 0;
  double? _closing;
  double _time = 0;

  double get _radius => ArenaRing.radius;

  @override
  Vector2 get spawnPoint => _polar(spawnAngle, _radius - 4);

  @override
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
    final c = type.colors;
    final r = _radius;
    final closing = _closing ?? 0;
    final open = Curves.easeOutCubic.transform(_form) * (1 - closing);
    // How far along the ring the tear reaches, each side
    final half = 0.05 + 0.17 * open;
    // How deep it bulges inward in the middle
    final depth = 4 + 16 * Curves.easeIn.transform(_form) * (1 - closing);
    const steps = 18;
    final inner = Path();
    final outer = Path();
    for (var i = 0; i <= steps; i++) {
      final k = i / steps;
      final a = spawnAngle - half + 2 * half * k;
      final bump = sin(k * pi);
      final flicker = 1 + 0.12 * sin(_time * 30 + k * 9);
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
    final life = _clamp01(_form * 4) * (1 - closing);
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
    final grow = Curves.easeOutBack.transform(_clamp01((_form - 0.65) / 0.35));
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

/// Idea 2: one fire and one ice spawner crawl along the arena ring. Each one
/// glides to where its next orb leaves from, charges up and throws. Where
/// it stops tells the player where to turn.
class RimCrawler extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState> {
  RimCrawler({required this.type, required this.clock})
    : _angle = type.isFire ? -pi / 2 : pi / 2,
      super(priority: 1);

  final OrbType type;

  /// The song time the throws are planned on
  final double Function() clock;

  /// How long it takes at most to glide to its next spot
  static const moveWindow = 0.7;

  /// It sits still this long before it throws, so the spot is clear
  static const hold = 0.12;

  final _queue = <_CrawlerThrow>[];
  double _angle;
  double _fromAngle = 0;
  double _fromTime = 0;
  double _trail = 0;
  double _kick = 0;
  double _time = 0;
  double _visible = 0;

  double get _radius => ArenaRing.radius;

  /// A throw it will make at [launchAt] (song time) from [angle]
  OrbTelegraph planThrow(double angle, double launchAt) {
    final t = _CrawlerThrow(this, angle, launchAt);
    if (_queue.isEmpty) {
      _fromAngle = _angle;
      _fromTime = clock();
    }
    _queue.add(t);
    return t;
  }

  void _thrown(_CrawlerThrow t) {
    _queue.remove(t);
    _angle = t.angle;
    _fromAngle = t.angle;
    _fromTime = clock();
    _kick = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _kick = max(0, _kick - dt * 3.5);
    final playing = bloc.state.playingState.isPlaying;
    _visible += ((playing ? 1.0 : 0.0) - _visible) * min(1, dt * 4);
    if (!playing) {
      _queue.clear();
      return;
    }
    final before = _angle;
    if (_queue.isEmpty) {
      // Idle: a slow patrol
      _angle += dt * 0.25 * (type.isFire ? 1 : -1);
    } else {
      final next = _queue.first;
      final now = clock();
      final start = max(_fromTime, next.launchAt - moveWindow);
      final arrive = max(start + 0.05, next.launchAt - hold);
      final k = _clamp01((now - start) / (arrive - start));
      var delta = (next.angle - _fromAngle) % (2 * pi);
      if (delta > pi) {
        delta -= 2 * pi;
      }
      _angle = _fromAngle + delta * Curves.easeInOutCubic.transform(k);
    }
    final speed = (_angle - before) / max(dt, 1e-4);
    _trail += (speed - _trail) * min(1, dt * 12);
  }

  /// How charged it is for the next throw, 0 to 1
  double get _charge {
    if (_queue.isEmpty) {
      return 0;
    }
    final left = _queue.first.launchAt - clock();
    return _clamp01(1 - left / moveWindow);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_visible <= 0.01) {
      return;
    }
    final c = type.colors;
    final r = _radius;
    final p = _polarOffset(_angle, r);
    final charge = _charge;
    // A tail along the ring while it moves
    final tail = (_trail * -0.12).clamp(-0.7, 0.7);
    if (tail.abs() > 0.01) {
      _lightStroke(
        canvas,
        _arc(r, _angle, tail),
        c,
        2.2,
        _visible * _clamp01(tail.abs() * 4),
      );
    }
    // Body: a bead of light that swells as it charges
    final size = 7 + 5 * charge + 6 * _kick;
    _bloom(canvas, p, size * 4, c[1], (0.35 + 0.4 * charge) * _visible);
    _orbHead(canvas, p, size * _visible, c);
    // Two little claws that grip the ring and open as it charges
    for (final side in [-1.0, 1.0]) {
      final a = _angle + side * (0.05 + 0.04 * charge);
      final from = _polarOffset(a, r + 6);
      final to = _polarOffset(a + side * 0.05, r - 4 - 6 * charge);
      _lightStroke(
        canvas,
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy),
        c,
        1.4,
        _visible * (0.5 + 0.5 * charge),
      );
    }
    // A pointer toward the potato when it's about to throw
    if (charge > 0.6) {
      final k = (charge - 0.6) / 0.4;
      final from = _polarOffset(_angle, r - 14);
      final to = _polarOffset(_angle, r - 14 - 30 * k);
      _lightStroke(
        canvas,
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy),
        c,
        1.2,
        k * 0.6 * _visible,
      );
    }
    if (_kick > 0) {
      final out = 1 - _kick;
      _lightStroke(
        canvas,
        Path()..addOval(Rect.fromCircle(center: p, radius: 10 + 26 * out)),
        c,
        1.6 * _kick,
        _kick,
      );
    }
    // Faint shimmer so it's alive even when idle
    _bloom(canvas, p, 3 + sin(_time * 6).abs() * 2, _white, 0.5 * _visible);
  }
}

class _CrawlerThrow implements OrbTelegraph {
  _CrawlerThrow(this.crawler, this.angle, this.launchAt);

  final RimCrawler crawler;
  final double angle;
  final double launchAt;

  @override
  Vector2 get spawnPoint => _polar(angle, crawler._radius - 4);

  @override
  void close() => crawler._thrown(this);
}

/// Idea 3: a ripple runs out from the potato to the ring along the path the
/// orb will take, flashes at the ring, then the orb comes back along it.
/// The warning uses the empty middle instead of space at the spawn point.
class RippleTelegraph extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState>
    implements OrbTelegraph {
  RippleTelegraph({
    required this.type,
    required this.spawnAngle,
    required this.formDuration,
  }) : super(priority: 0);

  final OrbType type;
  final double spawnAngle;
  final double formDuration;

  static const _closeDuration = 0.4;

  /// Where the ripple starts, just outside the shield
  static const _startRadius = 84.0;

  double _form = 0;
  double? _closing;

  double get _radius => ArenaRing.radius;

  @override
  Vector2 get spawnPoint => _polar(spawnAngle, _radius - 4);

  @override
  void close() => _closing ??= 0;

  @override
  void update(double dt) {
    super.update(dt);
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
    final c = type.colors;
    final r = _radius;
    final closing = _closing ?? 0;
    final fade = 1 - closing;
    // The ripple's front races out, fast at first then easing into the ring
    final k = Curves.easeOutCubic.transform(_form);
    final front = _startRadius + (r - _startRadius) * k;
    // A faint lane along the whole path
    final laneFrom = _polarOffset(spawnAngle, _startRadius);
    final laneTo = _polarOffset(spawnAngle, r);
    canvas.drawLine(
      laneFrom,
      laneTo,
      Paint()
        ..blendMode = BlendMode.plus
        ..strokeWidth = 1
        ..color = c[1].withValues(alpha: 0.18 * fade),
    );
    // The ripple: a short arc that widens as it travels, with a trail
    if (closing == 0) {
      for (var i = 0; i < 3; i++) {
        final behind = front - i * 16;
        if (behind < _startRadius) {
          continue;
        }
        final w =
            (0.06 + 0.1 * (behind - _startRadius) / (r - _startRadius)) *
            (1 - i * 0.25);
        _lightStroke(
          canvas,
          _arc(behind, spawnAngle - w, 2 * w),
          c,
          2.2 - i * 0.6,
          (1 - i * 0.35) * _clamp01(_form * 5),
        );
      }
    }
    // It lands on the ring: a splash that becomes the orb
    final land = _clamp01((_form - 0.8) / 0.2);
    final splashAt = _polarOffset(spawnAngle, r - 4);
    if (land > 0 && closing == 0) {
      _lightStroke(
        canvas,
        _arc(r, spawnAngle - 0.1 - 0.1 * land, 0.2 + 0.2 * land),
        c,
        2,
        land,
      );
      _orbHead(canvas, splashAt, 10 * Curves.easeOutBack.transform(land), c);
    }
    if (closing > 0) {
      _bloom(canvas, splashAt, 12 + 22 * closing, _white, 0.8 * fade * fade);
      _lightStroke(
        canvas,
        _arc(r, spawnAngle - 0.2 - 0.25 * closing, 0.4 + 0.5 * closing),
        c,
        2 * fade,
        fade,
      );
    }
  }
}
