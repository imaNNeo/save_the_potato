import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/widgets/background_stars.dart';
import 'package:save_the_potato/presentation/widgets/potato_initialize.dart';

/// Where the potato sits and how big it is when the game shows it, so the
/// splash can hand it over without a jump.
abstract final class GamePotatoFrame {
  /// The game potato's size in world units, see `Potato`
  static const double worldSize = 100;

  /// The game potato on a screen of [screen] size (it is centered). The
  /// camera fits the square view into the screen.
  static double screenSize(Size screen) =>
      worldSize * min(screen.width, screen.height) / GameConstants.viewSize;

  /// The [SplashPotato.size] that looks exactly like the game potato.
  static double splashPotatoSize(Size screen) =>
      SplashPotato.sizeForGamePotato(screenSize(screen));
}

/// The stars, exactly like the home screen shows them before the game starts,
/// so going from the splash to the game doesn't change the background.
class HomeStars extends StatelessWidget {
  const HomeStars({super.key, this.fadeIn = 1});

  /// From black (0) to the full stars (1)
  final double fadeIn;

  static double starsSize(BuildContext context) =>
      min(MediaQuery.sizeOf(context).width * 0.1, 80.0);

  @override
  Widget build(BuildContext context) {
    return BackgroundStars(
      backgroundColor: Color.lerp(
        Colors.black,
        GameColors.starsBackground[0],
        fadeIn,
      )!,
      starsColor: Color.lerp(Colors.black, GameColors.starsColors[0], fadeIn)!,
      timeScale: 0,
      starsSize: starsSize(context),
    );
  }
}

/// The animated splash: stars fade in, the potato pops in with a burst of
/// hot and cold sparks, the shields sweep around it and the title bounces in
/// letter by letter. [exit] shrinks the potato into the exact spot and size
/// the game shows it at, and clears everything else away.
class SplashStage extends StatefulWidget {
  const SplashStage({super.key, required this.footer});

  final Widget footer;

  @override
  State<SplashStage> createState() => SplashStageState();
}

class SplashStageState extends State<SplashStage>
    with TickerProviderStateMixin {
  static const _title = 'Save the Potato';

  static const _fire = GameConstants.redColors;
  static const _ice = GameConstants.blueColors;

  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  /// Keeps running so the idle splash breathes and the shields keep turning
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..forward();

  late final _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  /// Plays the way out, completes when the splash looks like the game.
  Future<void> exit() => _exit.forward().orCancel.catchError((_) {});

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _exit.dispose();
    super.dispose();
  }

  /// [t] seconds of the intro mapped to 0..1 over [from]..[to] seconds
  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _idle, _exit]),
      builder: (context, _) {
        final t = _intro.value * 2.2;
        final idle = _idle.value * 60;
        final exit = Curves.easeInOutCubic.transform(_exit.value);

        final fullSize = min(180.0, screen.shortestSide * 0.42);
        final gameSize = GamePotatoFrame.splashPotatoSize(screen);

        // Pops in at 0.25s with an elastic overshoot, then breathes
        final pop = _span(t, 0.25, 1.05);
        final popScale = pop == 0 ? 0.0 : Curves.elasticOut.transform(pop);
        final breathe =
            1 + 0.025 * sin(idle * 2.6) * _span(t, 1.0, 1.6) * (1 - exit);
        final size = lerpDouble(fullSize, gameSize, exit)!;
        final squash = 1 + 0.12 * sin(pop * pi * 3) * (1 - pop);
        final scaleX = popScale * breathe * squash;
        final scaleY = popScale * breathe / squash;

        final center = Offset(screen.width / 2, screen.height / 2);
        final fade = 1 - _span(_exit.value, 0, 0.6);

        return Stack(
          fit: StackFit.expand,
          children: [
            HomeStars(fadeIn: Curves.easeOut.transform(_span(t, 0, 0.8))),
            Positioned.fill(
              child: CustomPaint(
                painter: _SplashFxPainter(
                  center: center,
                  potatoRadius: size * 0.75 * popScale.clamp(0.0, 1.0),
                  t: t,
                  idle: idle,
                  exit: exit,
                ),
              ),
            ),
            Positioned(
              left: center.dx - size / 2,
              top: center.dy - size / 2,
              width: size,
              height: size,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                child: SplashPotato(size: size),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: center.dy + fullSize * 0.85 + 8,
              child: Transform.translate(
                offset: Offset(0, -40 * exit),
                child: _titleRow(t, idle, fade),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: _span(t, 1.2, 1.8) * fade,
                child: widget.footer,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Letters drop in one after another with a bounce, colored from hot to
  /// cold, then gently wave.
  Widget _titleRow(double t, double idle, double fade) {
    final letters = _title.split('');
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        // Fades through the colors, an extra layer would stutter the exit
        colors: [
          _fire[0].withValues(alpha: fade),
          Colors.white.withValues(alpha: fade),
          _ice[0].withValues(alpha: fade),
        ],
        stops: const [0.1, 0.5, 0.9],
      ).createShader(rect),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < letters.length; i++)
            _letter(letters[i], i, t, idle),
        ],
      ),
    );
  }

  Widget _letter(String letter, int i, double t, double idle) {
    final p = _span(t, 0.75 + i * 0.045, 1.35 + i * 0.045);
    final drop = Curves.bounceOut.transform(p);
    final wave = 3 * sin(idle * 3 - i * 0.55) * _span(t, 1.9, 2.2);
    return Opacity(
      opacity: _span(p, 0, 0.25),
      child: Transform.translate(
        offset: Offset(0, -70 * (1 - drop) + wave),
        child: Transform.scale(
          scale: 0.6 + 0.4 * Curves.easeOutBack.transform(p),
          child: Text(
            letter == ' ' ? '  ' : letter,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 12, color: Colors.white54)],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashFxPainter extends CustomPainter {
  _SplashFxPainter({
    required this.center,
    required this.potatoRadius,
    required this.t,
    required this.idle,
    required this.exit,
  });

  final Offset center;
  final double potatoRadius;
  final double t;
  final double idle;
  final double exit;

  static const _fire = GameConstants.redColors;
  static const _ice = GameConstants.blueColors;

  static const _popAt = 0.3;

  static final _sparks = () {
    final rnd = Random(7);
    return List.generate(26, (i) {
      return (
        angle: i / 26 * 2 * pi + rnd.nextDouble() * 0.3,
        speed: 0.7 + rnd.nextDouble() * 0.8,
        size: 2.0 + rnd.nextDouble() * 3.5,
        fire: i.isEven,
      );
    });
  }();

  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (potatoRadius <= 0 && t < _popAt) return;
    final r = max(potatoRadius, 1.0);
    final fade = 1 - exit;

    _paintHalo(canvas, r, fade);
    _paintShockwave(canvas, r);
    _paintSparks(canvas, r);
    _paintShields(canvas, r, fade);
    _paintHandoffFlash(canvas, r);
  }

  /// A warm glow on the left and a cold one on the right, breathing
  void _paintHalo(Canvas canvas, double r, double fade) {
    final on = _span(t, _popAt, 1.0) * fade;
    if (on <= 0) return;
    final pulse = 1 + 0.08 * sin(idle * 2.6);
    for (final (dx, color) in [(-0.35, _fire[1]), (0.35, _ice[1])]) {
      final c = center + Offset(dx * r, 0);
      final radius = r * 1.9 * pulse;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.38 * on),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }
  }

  /// One ring blasts out when the potato lands
  void _paintShockwave(Canvas canvas, double r) {
    final p = _span(t, _popAt, _popAt + 0.7);
    if (p <= 0 || p >= 1) return;
    final e = Curves.easeOutCubic.transform(p);
    canvas.drawCircle(
      center,
      r * (0.6 + 2.6 * e),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - e) + 1
        ..color = Colors.white.withValues(alpha: 0.7 * (1 - p)),
    );
  }

  /// Hot and cold sparks burst out of the landing
  void _paintSparks(Canvas canvas, double r) {
    final p = _span(t, _popAt, _popAt + 1.1);
    if (p <= 0 || p >= 1) return;
    final travel = Curves.easeOutQuart.transform(p);
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final s in _sparks) {
      final dir = Offset(cos(s.angle), sin(s.angle));
      final pos = center + dir * (r * 0.7 + r * 2.4 * s.speed * travel);
      final colors = s.fire ? _fire : _ice;
      final radius = s.size * (1 - p);
      paint.color = colors[0].withValues(alpha: 1 - p);
      canvas.drawCircle(pos, radius * 2.4, paint);
      paint.color = Colors.white.withValues(alpha: 1 - p);
      canvas.drawCircle(pos, radius * 0.9, paint);
    }
  }

  /// A fire and an ice shield sweep in and spin around the potato, then on
  /// the way out they wind up fast and close in on it.
  void _paintShields(Canvas canvas, double r, double fade) {
    final grow = Curves.easeOutCubic.transform(_span(t, 0.55, 1.25));
    if (grow <= 0 || fade <= 0) return;
    final radius = r * (1.32 - 0.25 * exit);
    final sweep = 2.1 * grow * (1 - 0.6 * exit);
    // Starts fast and settles into a slow turn, whips around on exit
    final spin = 6 * (1 - pow(1 - grow, 3)) + idle * 0.9 + exit * exit * 9;
    for (final (offset, colors) in [(0.0, _fire), (pi, _ice)]) {
      final start = spin + offset - sweep / 2;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.2
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = colors[1].withValues(alpha: 0.55 * fade),
      );
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.07
          ..color = Color.lerp(
            colors[0],
            Colors.white,
            0.5,
          )!.withValues(alpha: fade),
      );
    }
  }

  /// A soft flash as the potato settles into its game spot
  void _paintHandoffFlash(Canvas canvas, double r) {
    final p = _span(exit, 0.7, 1);
    if (p <= 0) return;
    final a = sin(p * pi) * 0.5;
    canvas.drawCircle(
      center,
      r * (1.1 + 0.8 * p),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: a),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashFxPainter old) => true;
}
