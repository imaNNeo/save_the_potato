import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/domain/life_meter.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'potato_painter.dart';
import 'potato_pose.dart';

/// Prototypes of showing the life on the potato's headphones, picked with
/// `?hp=<style>` on web. With a style set, the top bar hides.
enum HeadphonesHpStyle {
  /// Three big music notes standing on the headband
  notes,

  /// Sound waves out of the ear cups, like a volume icon
  waves,

  /// The headband itself lights up from both cups toward the top
  band;

  static final HeadphonesHpStyle? current = () {
    if (!kIsWeb) return null;
    final name = Uri.base.queryParameters['hp'];
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }();
}

const _ink = Color(0xFF2A1A18);
const _fire = Color(0xFFFF6A1A);
const _gold = Color(0xFFFFD34A);
const _ice = Color(0xFF2AB8FF);
const _white = Color(0xFFFFFFFF);

class _Flying {
  _Flying(this.pos, this.vel, this.spin, this.color);
  Offset pos;
  Offset vel;
  double angle = 0;
  final double spin;
  final Color color;
  double life = 1;
}

/// Keeps the life animation and draws it on the headphones through
/// [PotatoPainter.headphonesOverlay], so it follows the dance and the knocks.
class HeadphonesHp extends Component
    with FlameBlocListenable<GameCubit, GameState> {
  HeadphonesHp({required this.style});

  final HeadphonesHpStyle style;

  double _time = 0;
  double _life = LifeMeter.start;
  double _shown = LifeMeter.start;
  double _ghost = 0;
  double _ghostAlpha = 0;
  double _hit = 0;
  double _flash = 0;
  double _danger = 0;
  final _flying = <_Flying>[];
  final _rnd = Random(7);

  @override
  void onMount() {
    super.onMount();
    PotatoPainter.headphonesOverlay = _paint;
  }

  @override
  void onRemove() {
    if (PotatoPainter.headphonesOverlay == _paint) {
      PotatoPainter.headphonesOverlay = null;
    }
    super.onRemove();
  }

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
      _ghostAlpha = 0;
      return;
    }
    if (value < _life) {
      _onLost(_life, value);
      _ghost = _shown;
      _ghostAlpha = 1;
      _hit = 1;
    } else if (value > _life) {
      _flash = 1;
    }
    _life = value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_life < _shown) {
      _shown = _life;
    } else {
      _shown += (_life - _shown) * (1 - exp(-8 * dt));
    }
    _ghostAlpha = max(0, _ghostAlpha - dt * 1.4);
    _hit *= exp(-3 * dt);
    _flash *= exp(-5 * dt);
    final inDanger = _life > 0 && _life < LifeMeter.danger ? 1.0 : 0.0;
    _danger += (inDanger - _danger) * (1 - exp(-8 * dt));
    for (final f in _flying) {
      f.pos += f.vel * dt;
      f.vel += const Offset(0, 500) * dt;
      f.angle += f.spin * dt;
      f.life -= dt / 1.2;
    }
    _flying.removeWhere((f) => f.life <= 0);
  }

  double get _blink => _danger * (0.5 + 0.5 * sin(_time * 14));

  static double _part(int i, int count, double life) =>
      (life * count - i).clamp(0.0, 1.0);

  int _lastIndex(int count) =>
      (_shown * count - 1e-6).floor().clamp(0, count - 1);

  void _onLost(double from, double to) {
    if (style != HeadphonesHpStyle.notes) return;
    for (var i = 0; i < 3; i++) {
      if (_part(i, 3, from) - _part(i, 3, to) > 0.05) {
        final (p, _) = _noteSpot(i);
        final out = p.dx < 242 ? -1.0 : (p.dx > 242 ? 1.0 : 0.3);
        _flying.add(
          _Flying(
            p,
            Offset(out * 160 + (_rnd.nextDouble() - 0.5) * 60, -260),
            out * 5,
            _noteColors[i],
          ),
        );
      }
    }
  }

  void _paint(Canvas canvas, PotatoPose pose) {
    final on = pose[PotatoProp.headphones].clamp(0.0, 1.0);
    if (on <= 0.01) return;
    final pulse = pose[PotatoProp.headphonesPulse];
    switch (style) {
      case HeadphonesHpStyle.notes:
        _paintNotes(canvas, on, pulse);
      case HeadphonesHpStyle.waves:
        _paintWaves(canvas, on, pulse);
      case HeadphonesHpStyle.band:
        _paintBand(canvas, on, pulse);
    }
  }

  // ---- three notes on the headband ----

  static const _noteColors = [_fire, _gold, _ice];

  /// A point on the headband (same curve as the painter's band)
  static Offset _bandAt(double t) {
    const p0 = Offset(100, 226);
    const p1 = Offset(98, 34);
    const p2 = Offset(386, 34);
    const p3 = Offset(384, 226);
    final u = 1 - t;
    return p0 * (u * u * u) +
        p1 * (3 * u * u * t) +
        p2 * (3 * u * t * t) +
        p3 * (t * t * t);
  }

  /// Where note [i] stands, and how much it leans
  static (Offset, double) _noteSpot(int i) {
    const ts = [0.2, 0.5, 0.8];
    final t = ts[i];
    final p = _bandAt(t);
    final lean = (t - 0.5) * 0.9;
    return (p + Offset(sin(lean) * 40, -cos(lean) * 40), lean);
  }

  static final Path _notePath = () {
    final head = Path()
      ..addOval(Rect.fromCenter(center: Offset.zero, width: 40, height: 30));
    final m = Float64List(16)
      ..[0] = cos(-0.4)
      ..[1] = sin(-0.4)
      ..[4] = -sin(-0.4)
      ..[5] = cos(-0.4)
      ..[10] = 1
      ..[15] = 1;
    return Path()
      ..addPath(head.transform(m), Offset.zero)
      ..addRect(const Rect.fromLTRB(12, -84, 20, -4))
      ..addPath(
        Path()
          ..moveTo(12, -84)
          ..cubicTo(22, -70, 52, -64, 42, -30)
          ..cubicTo(44, -52, 28, -56, 18, -60)
          ..close(),
        Offset.zero,
      );
  }();

  void _drawNote(
    Canvas canvas,
    Offset at,
    double angle,
    double scale,
    double fill,
    Color color,
    double alpha, {
    bool last = false,
  }) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    final paint = Paint()..isAntiAlias = true;
    // Outline first: the fills cover where the parts overlap
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeJoin = StrokeJoin.round
      ..color = _ink.withValues(alpha: alpha * (fill > 0 ? 1 : 0.55));
    canvas.drawPath(_notePath, paint);
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4A3A38).withValues(alpha: alpha * 0.9);
    canvas.drawPath(_notePath, paint);
    if (fill > 0) {
      canvas.save();
      canvas.clipPath(_notePath);
      final top = 16 - fill * 104;
      paint
        ..color = _white.withValues(alpha: alpha)
        ..shader = Gradient.linear(const Offset(0, -84), const Offset(0, 16), [
          Color.lerp(color, _white, 0.55 + 0.4 * _flash)!,
          color,
        ]);
      canvas.drawRect(Rect.fromLTRB(-30, top, 60, 20), paint);
      paint.shader = null;
      canvas.restore();
      paint.color = _white.withValues(alpha: alpha * 0.8);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-7, -5), width: 12, height: 7),
        paint,
      );
      if (last && _danger > 0) {
        paint.color = const Color(0xFF200808)
            .withValues(alpha: alpha * 0.55 * _blink);
        canvas.drawPath(_notePath, paint);
      }
    }
    if (last && _hit > 0.02) {
      paint.color = _white.withValues(alpha: alpha * 0.8 * _hit);
      canvas.drawPath(_notePath, paint);
    }
    canvas.restore();
  }

  void _paintNotes(Canvas canvas, double on, double pulse) {
    final last = _lastIndex(3);
    for (var i = 0; i < 3; i++) {
      final (p, lean) = _noteSpot(i);
      final f = _part(i, 3, _shown);
      // Each note bops on the beat, one after another
      final bop = sin(_time * 6 + i * 1.2) * 0.04 + 0.08 * pulse;
      final shake = i == last ? sin(_time * 40) * 0.08 * _danger : 0.0;
      _drawNote(
        canvas,
        p,
        lean + shake + sin(_time * 3 + i) * 0.06,
        1.7 * (1 + bop + 0.12 * _flash * (f > 0 ? 1 : 0)) * (0.8 + 0.2 * f),
        f,
        _noteColors[i],
        on,
        last: i == last,
      );
    }
    for (final fl in _flying) {
      _drawNote(
        canvas,
        fl.pos,
        fl.angle,
        1.7,
        1,
        Color.lerp(fl.color, const Color(0xFF777777), 1 - fl.life)!,
        on * fl.life.clamp(0, 1),
      );
    }
  }

  // ---- sound waves out of the cups ----

  void _paintWaves(Canvas canvas, double on, double pulse) {
    final last = _lastIndex(3);
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (cup, dir, color) in const [
      (Offset(80, 244), pi, _fire),
      (Offset(404, 244), 0.0, _ice),
    ]) {
      for (var i = 0; i < 3; i++) {
        final f = _part(i, 3, _shown);
        final r = 46.0 + i * 34 + 8 * pulse;
        final sweep = 1.0 - i * 0.1;
        final rect = Rect.fromCircle(center: cup, radius: r);
        final isLast = i == last;
        // The empty slot
        paint
          ..strokeWidth = 18
          ..color = _ink.withValues(alpha: on * 0.4);
        canvas.drawArc(rect, dir - sweep / 2, sweep, false, paint);
        if (f <= 0) continue;
        final danger = isLast ? _blink : 0.0;
        final c = Color.lerp(
          Color.lerp(color, _white, 0.3 * _flash)!,
          const Color(0xFFFF2030),
          danger,
        )!;
        paint
          ..strokeWidth = 26
          ..color = _ink.withValues(alpha: on * f);
        canvas.drawArc(rect, dir - sweep / 2, sweep, false, paint);
        paint
          ..strokeWidth = 17
          ..color = c.withValues(alpha: on * f);
        canvas.drawArc(rect, dir - sweep / 2, sweep, false, paint);
        paint
          ..strokeWidth = 5
          ..color = _white.withValues(alpha: on * f * 0.8);
        canvas.drawArc(rect, dir - sweep / 2, sweep * 0.8, false, paint);
      }
      // The wave that was just lost, flying out and fading
      if (_ghostAlpha > 0) {
        final r = 46.0 + (_ghost * 3).clamp(0, 3) * 34 + (1 - _ghostAlpha) * 80;
        paint
          ..strokeWidth = 17 * _ghostAlpha
          ..color = const Color(0xFFFF3040).withValues(alpha: on * _ghostAlpha);
        canvas.drawArc(
          Rect.fromCircle(center: cup, radius: r),
          dir - 0.5,
          1.0,
          false,
          paint,
        );
      }
    }
  }

  // ---- the headband as a gauge ----

  static final Path _band = Path()
    ..moveTo(100, 226)
    ..cubicTo(98, 34, 386, 34, 384, 226);

  void _paintBand(Canvas canvas, double on, double pulse) {
    final metric = _band.computeMetrics().first;
    final len = metric.length;
    final half = len / 2 * _shown;
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dangerColor = const Color(0xFFFF2030);
    for (final (path, color) in [
      (metric.extractPath(0, half), _fire),
      (metric.extractPath(len - half, len), _ice),
    ]) {
      if (half <= 1) continue;
      final c = Color.lerp(
        Color.lerp(color, _white, 0.3 * _flash + 0.2 * pulse)!,
        dangerColor,
        _blink,
      )!;
      // Glow
      for (var k = 3; k >= 1; k--) {
        paint
          ..blendMode = BlendMode.plus
          ..strokeWidth = 22 + k * 14.0
          ..color = c.withValues(
            alpha: on * 0.12 / k * 3 * (0.6 + 0.4 * pulse),
          );
        canvas.drawPath(path, paint);
      }
      paint
        ..blendMode = BlendMode.srcOver
        ..strokeWidth = 30
        ..color = _ink.withValues(alpha: on);
      canvas.drawPath(path, paint);
      paint
        ..strokeWidth = 20
        ..color = c.withValues(alpha: on);
      canvas.drawPath(path, paint);
      paint
        ..strokeWidth = 6
        ..color = _white.withValues(alpha: on * 0.85);
      canvas.drawPath(path, paint);
    }
    // The part just lost flashes and fades
    if (_ghostAlpha > 0 && _ghost > _shown) {
      final g = len / 2 * _ghost;
      paint
        ..strokeWidth = 20
        ..color = Color.lerp(
          dangerColor,
          _white,
          _ghostAlpha,
        )!.withValues(alpha: on * _ghostAlpha);
      canvas.drawPath(metric.extractPath(half, g), paint);
      canvas.drawPath(metric.extractPath(len - g, len - half), paint);
    }
    // A note at the top, where the two halves meet when full
    final top = _bandAt(0.5) + const Offset(0, -24);
    final full = (_shown - 0.95).clamp(0.0, 0.05) * 20;
    _drawNote(
      canvas,
      top + const Offset(-4, -2),
      0,
      1.1 + 0.1 * pulse,
      full,
      _gold,
      on,
    );
  }
}
