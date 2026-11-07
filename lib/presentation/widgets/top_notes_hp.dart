import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/life_meter.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:flutter/foundation.dart';

/// Which top style `?hp=` picks on web, if any
enum TopNotesStyle {
  /// Three notes, a third of the life each
  top,

  /// One big note that fills up
  topOne;

  static final TopNotesStyle? current = () {
    if (!kIsWeb) return null;
    final name = Uri.base.queryParameters['hp'];
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }();
}

/// Prototype: the life as music notes on a short staff at the top of the
/// screen, in place of the bar (`?hp=top` or `?hp=topOne`).
class TopNotesHp extends StatefulWidget {
  const TopNotesHp({super.key, required this.style});

  final TopNotesStyle style;

  static const size = Size(300, 76);

  @override
  State<TopNotesHp> createState() => _TopNotesHpState();
}

class _TopNotesHpState extends State<TopNotesHp>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  late final _look = _Look(one: widget.style == TopNotesStyle.topOne);

  @override
  void initState() {
    super.initState();
    _look.snap(context.read<GameCubit>().state.life);
    _ticker = createTicker((elapsed) {
      final dt = min(0.05, (elapsed - _last).inMicroseconds / 1e6);
      _last = elapsed;
      _look.update(dt);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _look.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listenWhen: (p, c) =>
          p.life != c.life || p.playingState != c.playingState,
      listener: (context, state) {
        final ps = state.playingState;
        _look.opacity = ps.isPlaying || ps.isPaused ? 1.0 : 0.35;
        if (ps.isGuide || ps.isNone) {
          _look.snap(state.life);
        } else {
          _look.set(state.life);
        }
      },
      child: SizedBox.fromSize(
        size: TopNotesHp.size,
        child: RepaintBoundary(child: CustomPaint(painter: _Painter(_look))),
      ),
    );
  }
}

const _ink = Color(0xFF2A1A18);
const _white = Color(0xFFFFFFFF);
const _colors = [Color(0xFFFF6A1A), Color(0xFFFFD34A), Color(0xFF2AB8FF)];

class _Flying {
  _Flying(this.pos, this.vel, this.spin, this.color, this.scale);
  Offset pos;
  Offset vel;
  double angle = 0;
  final double spin;
  final Color color;
  final double scale;
  double life = 1;
}

class _Look extends ChangeNotifier {
  _Look({required this.one});

  final bool one;
  double time = 0;
  double life = LifeMeter.start;
  double shown = LifeMeter.start;
  double flash = 0;
  double hit = 0;
  double danger = 0;
  double opacity = 1;
  double shownOpacity = 1;
  final pops = [0.0, 0.0, 0.0];
  final flying = <_Flying>[];
  final _rnd = Random(3);

  int get count => one ? 1 : 3;

  static double part(int i, int count, double life) =>
      (life * count - i).clamp(0.0, 1.0);

  void snap(double v) {
    life = shown = v;
    flash = hit = 0;
    flying.clear();
  }

  void set(double v) {
    if (v < life) {
      hit = 1;
      for (var i = 0; i < count; i++) {
        if (part(i, count, life) - part(i, count, v) > 0.05) {
          final side = one ? 1.0 : (i - 1).toDouble();
          flying.add(
            _Flying(
              _Painter.spot(i, count),
              Offset(side * 90 + (_rnd.nextDouble() - 0.5) * 50, -140),
              (side == 0 ? 0.6 : side) * 5,
              one ? const Color(0xFFFF3A3A) : _colors[i],
              _Painter.scaleFor(count),
            ),
          );
        }
      }
      shown = v;
    } else if (v > life) {
      flash = 1;
      final i = (v * count - 1e-6).floor().clamp(0, count - 1);
      pops[i] = 1;
    }
    life = v;
  }

  void update(double dt) {
    time += dt;
    shown += (life - shown) * (1 - exp(-10 * dt));
    flash *= exp(-5 * dt);
    hit *= exp(-3 * dt);
    for (var i = 0; i < 3; i++) {
      pops[i] *= exp(-7 * dt);
    }
    final d = life > 0 && life < LifeMeter.danger ? 1.0 : 0.0;
    danger += (d - danger) * (1 - exp(-8 * dt));
    shownOpacity += (opacity - shownOpacity) * (1 - exp(-6 * dt));
    for (final f in flying) {
      f.pos += f.vel * dt;
      f.vel += const Offset(0, 420) * dt;
      f.angle += f.spin * dt;
      f.life -= dt / 0.9;
    }
    flying.removeWhere((f) => f.life <= 0);
    notifyListeners();
  }

  double get blink => danger * (0.5 + 0.5 * sin(time * 14));
}

final Path _notePath = () {
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

class _Painter extends CustomPainter {
  _Painter(this.look) : super(repaint: look);

  final _Look look;

  static double scaleFor(int count) => count == 1 ? 0.62 : 0.5;

  /// The note's head center sits on the staff; this is the head position
  static Offset spot(int i, int count) {
    if (count == 1) return const Offset(146, 54);
    return Offset(150 + (i - 1) * 62.0 - 6, 56 - i * 6.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = look.shownOpacity;
    if (a <= 0.01) return;
    final shake = Offset(sin(look.time * 60) * 4 * look.hit, 0);
    canvas.save();
    canvas.translate(shake.dx, shake.dy);
    _paintStaff(canvas, a);
    final count = look.count;
    final last = (look.shown * count - 1e-6).floor().clamp(0, count - 1);
    for (var i = 0; i < count; i++) {
      final f = _Look.part(i, count, look.shown);
      final bop = sin(look.time * 5 + i * 1.3) * 0.03;
      final isLast = i == last;
      final jitter = isLast ? sin(look.time * 40) * 0.09 * look.danger : 0.0;
      final color = count == 1
          ? Color.lerp(
              const Color(0xFFFF3A3A),
              _colors[1],
              (look.shown * 2).clamp(0.0, 1.0),
            )!
          : _colors[i];
      _drawNote(
        canvas,
        spot(i, count),
        jitter + sin(look.time * 2.5 + i) * 0.05,
        scaleFor(count) * (1 + bop + 0.25 * look.pops[i]) * (0.85 + 0.15 * f),
        f,
        color,
        a,
        dangerShade: isLast ? look.blink : 0,
        hit: isLast ? look.hit : 0,
      );
    }
    for (final fl in look.flying) {
      _drawNote(
        canvas,
        fl.pos,
        fl.angle,
        fl.scale,
        1,
        Color.lerp(fl.color, const Color(0xFF777777), 1 - fl.life)!,
        a * fl.life.clamp(0.0, 1.0),
      );
    }
    canvas.restore();
  }

  void _paintStaff(Canvas canvas, double a) {
    final paint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final redTint = look.blink;
    for (var k = 0; k < 5; k++) {
      final y = 34.0 + k * 7;
      paint.shader = LinearGradient(
        colors: [
          _white.withValues(alpha: 0),
          Color.lerp(
            _white,
            const Color(0xFFFF4050),
            redTint,
          )!.withValues(alpha: a * 0.28),
          _white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(40, y, 220, 1));
      canvas.drawLine(Offset(40, y), Offset(260, y), paint);
    }
  }

  void _drawNote(
    Canvas canvas,
    Offset at,
    double angle,
    double scale,
    double fill,
    Color color,
    double alpha, {
    double dangerShade = 0,
    double hit = 0,
  }) {
    final path = _notePath;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    final paint = Paint()..isAntiAlias = true;
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeJoin = StrokeJoin.round
      ..color = _ink.withValues(alpha: alpha * (fill > 0 ? 1 : 0.7));
    canvas.drawPath(path, paint);
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4A3A38).withValues(alpha: alpha * 0.85);
    canvas.drawPath(path, paint);
    if (fill > 0) {
      canvas.save();
      canvas.clipPath(path);
      final top = 16 - fill * 104;
      paint
        ..color = _white.withValues(alpha: alpha)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, _white, 0.5 + 0.45 * look.flash)!, color],
        ).createShader(const Rect.fromLTRB(0, -84, 1, 16));
      canvas.drawRect(Rect.fromLTRB(-30, top, 60, 20), paint);
      paint.shader = null;
      canvas.restore();
      paint.color = _white.withValues(alpha: alpha * 0.8);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-7, -5), width: 12, height: 7),
        paint,
      );
      if (dangerShade > 0) {
        paint.color = const Color(0xFF200808)
            .withValues(alpha: alpha * 0.55 * dangerShade);
        canvas.drawPath(path, paint);
      }
    }
    if (hit > 0.02) {
      paint.color = _white.withValues(alpha: alpha * 0.8 * hit);
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Painter oldDelegate) => false;
}
