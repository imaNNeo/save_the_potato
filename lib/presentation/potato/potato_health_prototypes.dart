import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/domain/life_meter.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'potato_painter.dart';

/// Prototypes of showing the life on the potato itself, picked with
/// `?hp=<style>` on web. With a style set, the top bar hides.
enum PotatoHealthStyle {
  /// Three hearts baked into the potato's belly
  baked,

  /// The skin gets scorched and frosted as life drops
  skin,

  /// The potato fills with warm light like a battery
  fill;

  static final PotatoHealthStyle? current = () {
    if (!kIsWeb) return null;
    final name = Uri.base.queryParameters['hp'];
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }();
}

Path _heartPath(double s) => Path()
  ..moveTo(0, s * 0.85)
  ..cubicTo(-s * 0.25, s * 0.6, -s * 1.0, s * 0.15, -s * 1.0, -s * 0.3)
  ..cubicTo(-s * 1.0, -s * 0.8, -s * 0.35, -s * 1.0, 0, -s * 0.5)
  ..cubicTo(s * 0.35, -s * 1.0, s * 1.0, -s * 0.8, s * 1.0, -s * 0.3)
  ..cubicTo(s * 1.0, s * 0.15, s * 0.25, s * 0.6, 0, s * 0.85)
  ..close();

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

class _Puff {
  _Puff(this.pos, this.vel, this.size, this.color);
  Offset pos;
  final Offset vel;
  final double size;
  final Color color;
  double life = 1;
}

/// Drawn over the code-drawn potato, in the same 152 box, in artboard units
class PotatoHealthOverlay extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState> {
  PotatoHealthOverlay({required this.style, super.position})
    : super(size: Vector2.all(152), anchor: Anchor.center);

  final PotatoHealthStyle style;

  double _time = 0;
  double _life = LifeMeter.start;
  double _shown = LifeMeter.start;
  double _hit = 0;
  double _flash = 0;
  double _danger = 0;
  double _slosh = 0;
  final _puffs = <_Puff>[];
  final _rnd = Random(5);

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.life != newState.life ||
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    final value = state.life;
    if (!state.playingState.isPlaying &&
        !state.playingState.isPaused &&
        !state.playingState.isGameOver) {
      _life = _shown = value;
      return;
    }
    if (value < _life) {
      _onLost(_life, value);
      _hit = 1;
      _slosh = 1;
    } else if (value > _life) {
      _flash = 1;
    }
    _life = value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    // Drops at once, fills smoothly
    if (_life < _shown) {
      _shown = _life;
    } else {
      _shown += (_life - _shown) * (1 - exp(-8 * dt));
    }
    _hit *= exp(-3 * dt);
    _flash *= exp(-5 * dt);
    _slosh *= exp(-1.5 * dt);
    final follow = 1 - exp(-8 * dt);
    final inDanger = _life > 0 && _life < LifeMeter.danger ? 1.0 : 0.0;
    _danger += (inDanger - _danger) * follow;
    for (final p in _puffs) {
      p.pos += p.vel * dt;
      p.life -= dt / 1.2;
    }
    _puffs.removeWhere((p) => p.life <= 0);
  }

  double get _beat {
    final period = 1.0 - 0.55 * _danger;
    final phase = (_time / period) % 1.0;
    return max(
      exp(-pow((phase - 0.05) / 0.06, 2).toDouble()),
      0.6 * exp(-pow((phase - 0.25) / 0.06, 2).toDouble()),
    );
  }

  double get _blink => _danger * (0.5 + 0.5 * sin(_time * 14));

  // ---- the three baked hearts ----

  static const _hearts = [Offset(176, 352), Offset(242, 366), Offset(308, 352)];
  static const _heartSize = 30.0;

  double _heartFill(int i, double life) =>
      (life * _hearts.length - i).clamp(0.0, 1.0);

  void _onLost(double from, double to) {
    switch (style) {
      case PotatoHealthStyle.baked:
        for (var i = 0; i < _hearts.length; i++) {
          if (_heartFill(i, from) - _heartFill(i, to) > 0.05) {
            for (var k = 0; k < 7; k++) {
              _puffs.add(
                _Puff(
                  _hearts[i] +
                      Offset(
                        (_rnd.nextDouble() - 0.5) * 40,
                        (_rnd.nextDouble() - 0.5) * 20,
                      ),
                  Offset(
                    (_rnd.nextDouble() - 0.5) * 40,
                    -60 - 60 * _rnd.nextDouble(),
                  ),
                  10 + 10 * _rnd.nextDouble(),
                  k < 3 ? const Color(0xFFFF8A3A) : const Color(0xFF6E6060),
                ),
              );
            }
          }
        }
      case PotatoHealthStyle.skin:
      case PotatoHealthStyle.fill:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    final scale = size.x / PotatoPainter.artboardSize;
    canvas.scale(scale);
    switch (style) {
      case PotatoHealthStyle.baked:
        _paintBaked(canvas);
      case PotatoHealthStyle.skin:
        _paintSkin(canvas);
      case PotatoHealthStyle.fill:
        _paintFill(canvas);
    }
    canvas.restore();
  }

  void _paintBaked(Canvas canvas) {
    final paint = Paint()..isAntiAlias = true;
    for (var i = 0; i < _hearts.length; i++) {
      final f = _heartFill(i, _shown);
      final lastFilled = f > 0 && _heartFill(i + 1, _shown) <= 0;
      final beat = lastFilled ? _beat * (0.06 + 0.1 * _danger) : 0.0;
      final s = _heartSize * (1 + beat + 0.12 * _flash * (f > 0 ? 1 : 0));
      final c = _hearts[i];
      canvas.save();
      canvas.translate(c.dx, c.dy);
      final heart = _heartPath(s);
      // The baked-in socket: darker toasted skin, a bit sunk in
      paint
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF9A5A2E);
      canvas.drawPath(heart, paint);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFF6A3A1E);
      canvas.drawPath(heart, paint);
      if (f > 0) {
        // Glowing ember filling the heart from the bottom
        canvas.save();
        canvas.clipPath(heart);
        final top = s * 0.85 - f * s * 1.85;
        paint
          ..style = PaintingStyle.fill
          ..shader = Gradient.linear(Offset(0, -s), Offset(0, s), [
            Color.lerp(
              const Color(0xFFFF7A4A),
              const Color(0xFFFFFFFF),
              0.4 * _flash,
            )!,
            const Color(0xFFE0203A),
          ]);
        canvas.drawRect(Rect.fromLTRB(-s * 1.2, top, s * 1.2, s), paint);
        paint.shader = null;
        canvas.restore();
        if (lastFilled && _danger > 0) {
          paint
            ..style = PaintingStyle.fill
            ..color = const Color(0xFF3A1008).withValues(alpha: 0.6 * _blink);
          canvas.drawPath(heart, paint);
        }
        // Shine
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * f);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(-s * 0.45, -s * 0.42),
            width: s * 0.45,
            height: s * 0.28,
          ),
          paint,
        );
        // Outline in the potato's ink
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = const Color(0xFF462724);
        canvas.drawPath(heart, paint);
      }
      if (_hit > 0.02 && lastFilled) {
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7 * _hit);
        canvas.drawPath(heart, paint);
      }
      canvas.restore();
    }
    _paintPuffs(canvas);
  }

  void _paintPuffs(Canvas canvas) {
    final paint = Paint();
    for (final p in _puffs) {
      final a = p.life.clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: 0.8 * a);
      canvas.drawCircle(p.pos, p.size * (1.6 - 0.6 * a), paint);
    }
  }

  // ---- scorched and frosted skin ----

  /// x, y, radius, how much life must be lost to show it, fire or ice
  static const _spots = [
    (150.0, 300.0, 34.0, 0.12, true),
    (338.0, 262.0, 32.0, 0.28, false),
    (210.0, 392.0, 30.0, 0.42, true),
    (300.0, 160.0, 28.0, 0.52, false),
    (128.0, 200.0, 26.0, 0.62, true),
    (312.0, 372.0, 34.0, 0.72, false),
    (190.0, 140.0, 24.0, 0.8, true),
  ];

  void _paintSkin(Canvas canvas) {
    final lost = 1 - _shown;
    canvas.save();
    canvas.clipPath(PotatoPainter.bodyOutline);
    final paint = Paint()..isAntiAlias = true;
    // Healthy: a glossy shine sweeping across now and then
    final healthy = _smooth(0.6, 0.9, _shown);
    if (healthy > 0) {
      final x = ((_time * 0.35) % 1.6) * 500 - 150;
      paint.shader = Gradient.linear(
        Offset(x - 60, 0),
        Offset(x + 60, 60),
        [
          const Color(0x00FFFFFF),
          Color.fromRGBO(255, 255, 255, 0.35 * healthy),
          const Color(0x00FFFFFF),
        ],
        [0, 0.5, 1],
      );
      canvas.drawRect(const Rect.fromLTWH(0, 0, 500, 500), paint);
      paint.shader = null;
    }
    for (final (x, y, r, at, fire) in _spots) {
      final a = _smooth(at, at + 0.1, lost);
      if (a <= 0) continue;
      final rr = r * 1.6 * (0.6 + 0.4 * a);
      final c = Offset(x, y);
      if (fire) {
        // Scorch: charred middle, glowing ember edge
        paint.shader = Gradient.radial(
          c,
          rr,
          [
            const Color(0xFF2A140C).withValues(alpha: 0.95 * a),
            const Color(0xFF5A2810).withValues(alpha: 0.85 * a),
            const Color(0xFFFF6A20).withValues(alpha: 0.6 * a),
            const Color(0x00FF6A20),
          ],
          [0, 0.55, 0.8, 1],
        );
        canvas.drawCircle(c, rr, paint);
        paint.shader = null;
        // Embers
        for (var k = 0; k < 3; k++) {
          final ang = k * 2.1 + x;
          final flick = 0.5 + 0.5 * sin(_time * 9 + k * 2 + y);
          paint.color = const Color(0xFFFFB040).withValues(alpha: a * flick);
          canvas.drawCircle(
            c + Offset(cos(ang), sin(ang)) * rr * 0.35,
            4,
            paint,
          );
        }
      } else {
        // Frost: icy patch with crystals
        paint.shader = Gradient.radial(
          c,
          rr,
          [
            const Color(0xFFEAF8FF).withValues(alpha: 0.95 * a),
            const Color(0xFF8AD4FF).withValues(alpha: 0.8 * a),
            const Color(0x008AD4FF),
          ],
          [0, 0.6, 1],
        );
        canvas.drawCircle(c, rr, paint);
        paint
          ..shader = null
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * a);
        for (var k = 0; k < 3; k++) {
          final ang = k * pi / 3 + x;
          final d = Offset(cos(ang), sin(ang)) * rr * 0.45;
          canvas.drawLine(c - d, c + d, paint);
        }
        paint.style = PaintingStyle.fill;
      }
    }
    // In danger: cracks across the skin
    final crack = _smooth(0.75, 0.85, lost);
    if (crack > 0) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF3A1A10).withValues(alpha: crack * 0.9);
      canvas.drawPath(
        Path()
          ..moveTo(110, 250)
          ..lineTo(140, 262)
          ..lineTo(132, 286)
          ..lineTo(160, 300)
          ..moveTo(375, 300)
          ..lineTo(350, 312)
          ..lineTo(358, 336)
          ..lineTo(332, 352),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }
    canvas.restore();
    // Sweat drop in danger
    if (_danger > 0.05) {
      final t = (_time * 0.8) % 1.0;
      final p = Offset(370, 170 + 60 * t);
      paint
        ..shader = null
        ..color = const Color(0xFF9EDCFF).withValues(alpha: _danger * (1 - t));
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - 22)
          ..quadraticBezierTo(p.dx + 14, p.dy, p.dx, p.dy + 8)
          ..quadraticBezierTo(p.dx - 14, p.dy, p.dx, p.dy - 22),
        paint,
      );
    }
    // A red flash on a hit
    if (_hit > 0.02) {
      paint.color = const Color(0xFFFF3040).withValues(alpha: 0.35 * _hit);
      canvas.drawPath(PotatoPainter.bodyOutline, paint);
    }
  }

  // ---- filled with warm light ----

  void _paintFill(Canvas canvas) {
    const top = 100.0;
    const bottom = 416.0;
    final level = bottom - (bottom - top) * _shown;
    final color = Color.lerp(
      const Color(0xFFFF2040),
      const Color(0xFFFFB830),
      _smooth(0.15, 0.7, _shown),
    )!;
    final glow =
        (0.38 + 0.12 * _beat * (0.4 + _danger) + 0.25 * _flash) *
        (1 - 0.5 * _blink);
    canvas.save();
    canvas.clipPath(PotatoPainter.bodyOutline);
    final amp = 6 + 22 * _slosh;
    final wave = Path()..moveTo(80, 440);
    for (var i = 0; i <= 34; i++) {
      final x = 80 + i * 10.0;
      wave.lineTo(
        x,
        level +
            sin(_time * 5 + i * 0.45) * amp * 0.6 +
            sin(_time * 3.1 - i * 0.3) * amp * 0.4,
      );
    }
    wave
      ..lineTo(420, 440)
      ..close();
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = Gradient.linear(Offset(0, level), const Offset(0, bottom), [
        color.withValues(alpha: glow),
        color.withValues(alpha: glow * 0.55),
      ]);
    canvas.drawPath(wave, paint);
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFFFFF0C0).withValues(alpha: 0.7 * glow / 0.4);
    final surface = Path();
    for (var i = 0; i <= 34; i++) {
      final x = 80 + i * 10.0;
      final y =
          level +
          sin(_time * 5 + i * 0.45) * amp * 0.6 +
          sin(_time * 3.1 - i * 0.3) * amp * 0.4;
      if (i == 0) {
        surface.moveTo(x, y);
      } else {
        surface.lineTo(x, y);
      }
    }
    canvas.drawPath(surface, paint);
    // Bubbles rising in the light
    paint.style = PaintingStyle.fill;
    for (var k = 0; k < 9; k++) {
      final speed = 0.25 + 0.08 * (k % 4);
      final t = (_time * speed + k * 0.37) % 1.0;
      final y = bottom - t * (bottom - level);
      final x = 150 + ((k * 73) % 190) + 8 * sin(_time * 2 + k);
      paint.color = const Color(0xFFFFF4D0).withValues(alpha: 0.5 * (1 - t));
      canvas.drawCircle(Offset(x, y), 5 + (k % 3) * 2, paint);
    }
    canvas.restore();
  }
}
