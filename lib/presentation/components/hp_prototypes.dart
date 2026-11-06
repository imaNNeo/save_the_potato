import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors, Curves;
import 'package:save_the_potato/domain/life_meter.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/widgets/life_bar.dart';

/// Prototypes of other ways to show the life, near or on the potato.
/// Picked with `?hp=<style>` on web. With a style set, the top bar hides.
enum HpStyle {
  /// The arena ring is the life gauge
  arena,

  /// A thin ring just outside the shields
  halo,

  /// Five hearts orbiting the potato
  hearts,

  /// A beating heart on the potato's belly, filled like a glass of juice
  belly,

  /// A glow of life behind the potato
  aura;

  static final HpStyle? current = () {
    if (!kIsWeb) return null;
    final name = Uri.base.queryParameters['hp'];
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }();
}

Path heartPath(double s) => Path()
  ..moveTo(0, s * 0.85)
  ..cubicTo(-s * 0.25, s * 0.6, -s * 1.0, s * 0.15, -s * 1.0, -s * 0.3)
  ..cubicTo(-s * 1.0, -s * 0.8, -s * 0.35, -s * 1.0, 0, -s * 0.5)
  ..cubicTo(s * 0.35, -s * 1.0, s * 1.0, -s * 0.8, s * 1.0, -s * 0.3)
  ..cubicTo(s * 1.0, s * 0.15, s * 0.25, s * 0.6, 0, s * 0.85)
  ..close();

const _heartRed = Color(0xFFFF2F4A);
const _heartDark = Color(0xFF8A0C20);

class _Shard {
  _Shard(this.pos, this.vel, this.spin, this.size, this.color);
  Offset pos;
  Offset vel;
  double angle = 0;
  final double spin;
  final double size;
  final Color color;
  double life = 1;
}

/// Lives inside the potato, centered on it. [front] draws over the potato,
/// otherwise behind it.
class HpPrototype extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState> {
  HpPrototype({required this.style, required this.front, required Vector2 at})
    : super(position: at, priority: front ? 50 : -5);

  final HpStyle style;
  final bool front;

  double _time = 0;
  double _life = LifeMeter.start;
  double _shown = LifeMeter.start;
  double _ghost = 0;
  double _ghostAlpha = 0;
  double _ghostDelay = 0;
  double _hit = 0;
  double _flash = 0;
  double _levelUp = 0;
  double _danger = 0;
  double _visible = 0.4;
  double _shock = 0;
  Color _color = LifeBar.stageColors[LifeMeter.stageOf(LifeMeter.start)];
  final _shards = <_Shard>[];
  final _rnd = Random(3);

  int get _stage => LifeMeter.stageOf(_life);

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.life != newState.life ||
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    if (!state.playingState.isPlaying && !state.playingState.isPaused) {
      if (!state.playingState.isGameOver) {
        _life = _shown = state.life;
        _ghostAlpha = 0;
      }
    }
    final value = state.life;
    if (value < _life) {
      _ghost = max(_shown, _ghostAlpha > 0 ? _ghost : 0);
      _ghostAlpha = 1;
      _ghostDelay = 0.35;
      _onLost(_life, value);
      _shown = value;
      _hit = 1;
      _shock = 1;
    } else if (value > _life) {
      _flash = 1;
    }
    final before = _stage;
    _life = value;
    if (_stage > before) _levelUp = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _shown += (_life - _shown) * (1 - exp(-10 * dt));
    if (_ghostDelay > 0) {
      _ghostDelay -= dt;
    } else {
      _ghostAlpha = max(0, _ghostAlpha - dt * 1.6);
    }
    _hit *= exp(-3.5 * dt);
    _flash *= exp(-5 * dt);
    _levelUp = max(0, _levelUp - dt / 0.9);
    _shock = max(0, _shock - dt / 0.7);
    final follow = 1 - exp(-8 * dt);
    _color = Color.lerp(_color, LifeBar.stageColors[_stage], follow)!;
    _danger += ((_stage == 0 && _life > 0 ? 1 : 0) - _danger) * follow;
    final s = bloc.state.playingState;
    final target = s.isPlaying || s.isPaused ? 1.0 : 0.45;
    _visible += (target - _visible) * min(1, dt * 3);
    for (final p in _shards) {
      p.pos += p.vel * dt;
      p.vel = p.vel * exp(-1.2 * dt) + const Offset(0, 60) * dt;
      p.angle += p.spin * dt;
      p.life -= dt / 1.1;
    }
    _shards.removeWhere((p) => p.life <= 0);
  }

  /// A "lub-dub" beat, 0..1, faster in danger
  double get _beat {
    final period = 1.0 - 0.55 * _danger;
    final phase = (_time / period) % 1.0;
    return max(
      exp(-pow((phase - 0.05) / 0.06, 2).toDouble()),
      0.6 * exp(-pow((phase - 0.25) / 0.06, 2).toDouble()),
    );
  }

  double get _dangerBlink => _danger * (0.5 + 0.5 * sin(_time * 14));

  // ---- what happens when life is lost ----

  void _onLost(double from, double to) {
    switch (style) {
      case HpStyle.arena:
        _shatterArc(ArenaRing.radius, from, to, 22, 7);
      case HpStyle.halo:
        _shatterArc(_haloRadius, from, to, 14, 4);
      case HpStyle.hearts:
        for (var i = 0; i < _heartCount; i++) {
          final before = (from * _heartCount - i).clamp(0.0, 1.0);
          final after = (to * _heartCount - i).clamp(0.0, 1.0);
          if (before - after > 0.05) {
            final c = _heartCenter(i);
            for (var k = 0; k < 2; k++) {
              final dir = c.direction + (k == 0 ? -0.5 : 0.5);
              _shards.add(
                _Shard(
                  c + Offset(k == 0 ? -3 : 3, 0),
                  Offset(cos(dir), sin(dir)) * (70 + 40 * _rnd.nextDouble()),
                  (k == 0 ? -1 : 1) * (3 + 2 * _rnd.nextDouble()),
                  _heartSize,
                  _heartRed,
                ),
              );
            }
          }
        }
      case HpStyle.belly:
        for (var k = 0; k < 10; k++) {
          final a = -pi / 2 + (k - 4.5) * 0.35;
          _shards.add(
            _Shard(
              _bellyCenter + Offset(0, -_bellySize * 0.2),
              Offset(cos(a), sin(a)) * (60 + 60 * _rnd.nextDouble()),
              4,
              2.5,
              _heartRed,
            ),
          );
        }
      case HpStyle.aura:
        break;
    }
  }

  void _shatterArc(double r, double from, double to, int count, double size) {
    for (var k = 0; k < count; k++) {
      final f = to + (from - to) * _rnd.nextDouble();
      final side = k.isEven ? 1 : -1;
      final a = -pi / 2 + side * pi * f;
      final dir = Offset(cos(a), sin(a));
      _shards.add(
        _Shard(
          dir * r,
          dir * (30 + 60 * _rnd.nextDouble()) +
              Offset(_rnd.nextDouble() - 0.5, _rnd.nextDouble() - 0.5) * 60,
          (_rnd.nextDouble() - 0.5) * 12,
          size * (0.5 + _rnd.nextDouble()),
          Color.lerp(_color, Colors.white, 0.3)!,
        ),
      );
    }
  }

  void _paintShards(Canvas canvas, {bool hearts = false}) {
    final paint = Paint();
    for (final p in _shards) {
      final a = p.life.clamp(0.0, 1.0) * _visible;
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.angle);
      if (hearts) {
        // Half a heart flying off
        canvas.clipRect(
          Rect.fromLTWH(p.spin < 0 ? -p.size : 0, -p.size, p.size, p.size * 2),
        );
        canvas.drawPath(
          heartPath(p.size),
          paint..color = p.color.withValues(alpha: a),
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint..color = p.color.withValues(alpha: a),
        );
      }
      canvas.restore();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    switch (style) {
      case HpStyle.arena:
        if (front) {
          _paintRingGauge(canvas, ArenaRing.radius, 5, 16);
        }
      case HpStyle.halo:
        if (front) {
          _paintRingGauge(canvas, _haloRadius, 3.5, 9);
        }
      case HpStyle.hearts:
        if (front) {
          _paintHearts(canvas);
        }
      case HpStyle.belly:
        if (front) {
          _paintBelly(canvas);
        }
      case HpStyle.aura:
        if (front) {
          _paintAuraFront(canvas);
        } else {
          _paintAuraBack(canvas);
        }
    }
  }

  // ---- arena / halo: a ring that fills from the top down both sides ----

  static const _haloRadius = 84.0;

  void _paintRingGauge(
    Canvas canvas,
    double r,
    double width,
    double heartSize,
  ) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final v = _visible;
    final pulse = 0.5 + 0.5 * sin(_time * 11);
    // The empty track
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = Color.lerp(
          const Color(0xFF20202A),
          const Color(0xFF5A0A14),
          _danger * pulse,
        )!.withValues(alpha: 0.75 * v),
    );
    final sweep = pi * _shown;
    final c = Color.lerp(_color, Colors.white, 0.25 * _flash)!;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;
    // Soft glow: a few wide faint strokes
    for (var i = 3; i >= 1; i--) {
      glow
        ..strokeWidth = width + i * width * 1.3
        ..color = c.withValues(
          alpha: (0.10 + 0.1 * _flash + 0.15 * _levelUp) * v / i,
        );
      canvas.drawArc(rect, -pi / 2, sweep, false, glow);
      canvas.drawArc(rect, -pi / 2, -sweep, false, glow);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = c.withValues(alpha: v * (1 - 0.5 * _dangerBlink));
    canvas.drawArc(rect, -pi / 2, sweep, false, line);
    canvas.drawArc(rect, -pi / 2, -sweep, false, line);
    // Hot thin core
    line
      ..strokeWidth = width * 0.35
      ..color = Colors.white.withValues(alpha: 0.6 * v);
    canvas.drawArc(rect, -pi / 2, sweep, false, line);
    canvas.drawArc(rect, -pi / 2, -sweep, false, line);
    // Ends of the fill meet at the bottom: little sparks at the tips
    for (final side in [1, -1]) {
      final a = -pi / 2 + side * sweep;
      canvas.drawCircle(
        Offset(cos(a), sin(a)) * r,
        width * (0.9 + 0.3 * _flash),
        Paint()..color = Colors.white.withValues(alpha: 0.9 * v),
      );
    }
    // The lost part, flashing then gone
    if (_ghostAlpha > 0 && _ghost > _shown) {
      final from = pi * _shown;
      final to = pi * _ghost;
      final ghost = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = Color.lerp(
          const Color(0xFFFF4050),
          Colors.white,
          _ghostAlpha,
        )!.withValues(alpha: _ghostAlpha * v);
      canvas.drawArc(rect, -pi / 2 + from, to - from, false, ghost);
      canvas.drawArc(rect, -pi / 2 - from, -(to - from), false, ghost);
    }
    _paintShards(canvas);
    _paintHeart(canvas, Offset(0, -r), heartSize);
  }

  void _paintHeart(Canvas canvas, Offset at, double size, {double? fill}) {
    final v = _visible;
    final scale =
        1 +
        _beat * (0.08 + 0.12 * _danger) +
        0.2 * _flash +
        0.3 * _levelUp * _levelUp;
    final s = size * scale;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    final heart = heartPath(s);
    canvas.drawPath(
      heart,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, s * 0.22)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF0B0B10).withValues(alpha: 0.9 * v),
    );
    if (fill != null) {
      canvas.drawPath(
        heart,
        Paint()..color = const Color(0xFF2A0810).withValues(alpha: v),
      );
      canvas.save();
      canvas.clipPath(heart);
      // Juice level with a wobbling surface
      final top = s * 0.85 - fill * s * 1.85;
      final wave = Path()..moveTo(-s * 1.2, s);
      for (var i = 0; i <= 12; i++) {
        final x = -s * 1.2 + i * s * 0.2;
        wave.lineTo(x, top + sin(_time * 6 + i * 0.9) * s * 0.07 * (1 - fill));
      }
      wave
        ..lineTo(s * 1.2, s)
        ..close();
      canvas.drawPath(
        wave,
        Paint()
          ..color = Color.lerp(
            _heartRed,
            Colors.white,
            0.2 * _flash,
          )!.withValues(alpha: v * (1 - 0.5 * _dangerBlink)),
      );
      canvas.restore();
    } else {
      canvas.drawPath(
        heart,
        Paint()
          ..color = Color.lerp(
            _heartRed,
            _heartDark,
            0.3 * _dangerBlink,
          )!.withValues(alpha: v),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-s * 0.45, -s * 0.45),
        width: s * 0.5,
        height: s * 0.32,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.6 * v),
    );
    if (_hit > 0.01) {
      canvas.drawPath(
        heart,
        Paint()..color = Colors.white.withValues(alpha: _hit * 0.85 * v),
      );
    }
    canvas.restore();
  }

  // ---- hearts orbiting the potato ----

  static const _heartCount = 5;
  static const _heartSize = 9.0;
  static const _heartOrbit = 90.0;

  Offset _heartCenter(int i) {
    final a = -pi / 2 + _time * 0.35 + i * 2 * pi / _heartCount;
    return Offset(cos(a), sin(a)) * _heartOrbit;
  }

  void _paintHearts(Canvas canvas) {
    final v = _visible;
    for (var i = 0; i < _heartCount; i++) {
      final f = (_shown * _heartCount - i).clamp(0.0, 1.0);
      final c = _heartCenter(i);
      final isLast = f > 0 && (_shown * _heartCount - i) < 1.0;
      final bob = sin(_time * 3 + i) * 1.5;
      final at = c + Offset(0, bob);
      if (f <= 0) {
        // An empty heart: just its outline
        canvas.drawPath(
          heartPath(_heartSize).shift(at),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.25 * v),
        );
        continue;
      }
      final s = _heartSize * (isLast ? 1 + _beat * 0.15 : 1);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      final heart = heartPath(s);
      canvas.drawPath(
        heart,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFF0B0B10).withValues(alpha: 0.85 * v),
      );
      canvas.drawPath(
        heart,
        Paint()..color = const Color(0xFF3A0A14).withValues(alpha: 0.9 * v),
      );
      canvas.save();
      canvas.clipPath(heart);
      canvas.drawRect(
        Rect.fromLTRB(-s, s * 0.85 - f * s * 1.85, s, s),
        Paint()
          ..color = Color.lerp(
            _heartRed,
            Colors.white,
            0.3 * _flash,
          )!.withValues(alpha: v * (1 - 0.6 * _dangerBlink)),
      );
      canvas.restore();
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-s * 0.45, -s * 0.45),
          width: s * 0.5,
          height: s * 0.32,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.55 * v),
      );
      canvas.restore();
    }
    _paintShards(canvas, hearts: true);
  }

  // ---- a heart on the potato's belly ----

  static const _bellyCenter = Offset(0, 38);
  static const _bellySize = 11.0;

  void _paintBelly(Canvas canvas) {
    final v = _visible;
    // A soft red glow behind it so it reads on the potato skin
    canvas.drawCircle(
      _bellyCenter,
      _bellySize * 1.8,
      Paint()
        ..shader = Gradient.radial(_bellyCenter, _bellySize * 1.8, [
          _heartRed.withValues(alpha: (0.25 + 0.35 * _beat) * v),
          _heartRed.withValues(alpha: 0),
        ]),
    );
    _paintHeart(canvas, _bellyCenter, _bellySize, fill: _shown);
    _paintShards(canvas);
  }

  // ---- a glow of life around the potato ----

  void _paintAuraBack(Canvas canvas) {
    final v = _visible;
    final warm = Color.lerp(
      const Color(0xFFFF2038),
      const Color(0xFFFFC040),
      Curves.easeOut.transform(_shown.clamp(0.0, 1.0)),
    )!;
    final flicker = _danger * (0.4 + 0.4 * sin(_time * 23) * sin(_time * 7));
    final r = 50 + 75 * _shown + 12 * _beat * (0.5 + _danger) + 14 * _flash;
    final a = ((0.45 + 0.5 * _shown + 0.25 * _flash) * (1 - flicker)) * v;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = Gradient.radial(
          Offset.zero,
          r,
          [
            warm.withValues(alpha: a),
            warm.withValues(alpha: a * 0.5),
            warm.withValues(alpha: 0),
          ],
          [0.3, 0.6, 1.0],
        ),
    );
    // Motes of light circling: one per 10% of life
    final motes = (_shown * 12).round();
    for (var i = 0; i < motes; i++) {
      final ang = _time * (0.6 + 0.1 * (i % 3)) + i * 2 * pi / 12;
      final rr = 58 + 14 * sin(_time * 1.3 + i * 2.1) + 18 * _shown;
      canvas.drawCircle(
        Offset(cos(ang), sin(ang)) * rr,
        1.6 + 0.8 * sin(_time * 4 + i),
        Paint()
          ..color = Color.lerp(
            warm,
            Colors.white,
            0.6,
          )!.withValues(alpha: 0.8 * v),
      );
    }
  }

  void _paintAuraFront(Canvas canvas) {
    // A red shock wave out of the potato on a miss
    if (_shock > 0) {
      final t = 1 - _shock;
      canvas.drawCircle(
        Offset.zero,
        40 + 120 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * _shock
          ..color = const Color(0xFFFF3040)
              .withValues(alpha: _shock * _visible),
      );
    }
  }
}
