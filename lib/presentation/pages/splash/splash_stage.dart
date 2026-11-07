import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/pages/splash/splash_loading.dart';
import 'package:save_the_potato/presentation/widgets/background_stars.dart';
import 'package:save_the_potato/presentation/potato/potato_painter.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';
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

/// The animated splash: the stars fade in, the potato pops in, its
/// headphones drop onto its head and it grooves to a silent beat while notes
/// float out of the ear cups, then the title shows up. [exit] shrinks the
/// potato into the exact spot and size the game shows it at (headphones
/// still on, like the start screen) and clears everything else away.
class SplashStage extends StatefulWidget {
  const SplashStage({
    super.key,
    required this.footer,
    this.loadingProgress = 1,
  });

  final Widget footer;

  /// How much is loaded, 0..1. Shown only when loading takes longer than
  /// the intro animation.
  final double loadingProgress;

  @override
  State<SplashStage> createState() => SplashStageState();
}

class SplashStageState extends State<SplashStage>
    with TickerProviderStateMixin {
  static const _title = 'Save the Potato';

  static const _fire = GameConstants.redColors;
  static const _ice = GameConstants.blueColors;

  /// One beat of the silent tune the potato grooves to
  static const _beat = 0.5;

  /// When the headphones land
  static const _dropAt = 0.9;
  static const _dropTime = 0.45;

  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..forward();

  late final _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  /// Loading that is done before this many seconds isn't shown at all
  static const _loadingShowsAt = 1.2;
  static const _loadingFadeIn = 0.4;

  /// When the loading meter started to show, null while hidden
  double? _loadingShownAt;

  /// The progress on screen, it eases to [SplashStage.loadingProgress]
  double _shownProgress = 0;
  double _lastT = 0;

  void _updateLoading(double t) {
    final dt = (t - _lastT).clamp(0.0, 0.1);
    _lastT = t;
    final target = widget.loadingProgress.clamp(0.0, 1.0);
    _shownProgress += (target - _shownProgress) * min(1.0, dt * 10);
    if (target - _shownProgress < 0.002) _shownProgress = target;
    if (_loadingShownAt == null && t >= _loadingShowsAt && target < 1) {
      _loadingShownAt = t;
    }
  }

  double _loadingOpacity(double t, double fade) {
    final shownAt = _loadingShownAt;
    if (shownAt == null) return 0;
    return Curves.easeOut.transform(
          _span(t, shownAt, shownAt + _loadingFadeIn),
        ) *
        fade;
  }

  /// Plays the way out, completes when the splash looks like the game.
  Future<void> exit() => _exit.forward().orCancel.catchError((_) {});

  @override
  void dispose() {
    _clock.dispose();
    _exit.dispose();
    super.dispose();
  }

  /// [t] seconds mapped to 0..1 over [from]..[to] seconds
  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  double get _t => _clock.value * 60;

  double get _exitT => Curves.easeInOutCubic.transform(_exit.value);

  /// How much the potato grooves, 0..1
  double _groove(double t) {
    const start = _dropAt + _dropTime;
    return _span(t, start, start + 0.4) * (1 - _exitT);
  }

  /// 0 at a beat, rising to 1 just before the next one
  static double _beatPhase(double t) => (t / _beat) % 1;

  /// A quick kick right on the beat that fades over it
  static double _kick(double t) => pow(1 - _beatPhase(t), 3).toDouble();

  double _headphonesOn(double t) {
    // Same drop as in the game. They stay on, the start screen has them too
    return _easeOutBack(_span(t, _dropAt, _dropAt + _dropTime));
  }

  static double _easeOutBack(double x) {
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2);
  }

  /// Moves the potato with the beat, on top of its idle animation
  void _decorate(PotatoPose pose, double _) {
    final t = _t;
    final groove = _groove(t);
    final kick = _kick(t);
    final sway = sin(t / _beat * pi);
    pose[PotatoProp.headphones] = _headphonesOn(t);
    pose[PotatoProp.headphonesPulse] = kick * groove;
    pose[PotatoProp.eyeBliss] = groove;
    pose[PotatoProp.bodyY] = 6 * kick * groove;
    pose[PotatoProp.bodyScaleY] = 1 - 0.035 * kick * groove;
    pose[PotatoProp.bodyScaleX] = 1 + 0.025 * kick * groove;
    pose[PotatoProp.bodyAngle] = 0.05 * sway * groove;
    pose[PotatoProp.sing] = 0.4 * kick * groove;
    // A little bump when the headphones land on its head
    {
      final land = _span(
        t,
        _dropAt + _dropTime * 0.6,
        _dropAt + _dropTime + 0.3,
      );
      if (land > 0 && land < 1) {
        final squash = sin(land * pi) * (1 - land);
        pose[PotatoProp.bodyScaleY] -= 0.08 * squash;
        pose[PotatoProp.bodyScaleX] += 0.06 * squash;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_clock, _exit]),
      builder: (context, child) {
        final t = _t;
        final exit = _exitT;
        _updateLoading(t);

        final fullSize = min(180.0, screen.shortestSide * 0.42);
        final gameSize = GamePotatoFrame.splashPotatoSize(screen);
        final size = lerpDouble(fullSize, gameSize, exit)!;
        // A soft pop in, no big bounce
        final appear = Curves.easeOutBack.transform(_span(t, 0.15, 0.6));

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
                  potatoSize: size,
                  t: t,
                  groove: _groove(t),
                  fade: fade,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: SplashLoadingPainter(
                  center: center,
                  potatoSize: fullSize,
                  progress: _shownProgress,
                  opacity: _loadingOpacity(t, fade),
                  beat: _kick(t) * _groove(t),
                ),
              ),
            ),
            Positioned(
              left: center.dx - size / 2,
              top: center.dy - size / 2,
              width: size,
              height: size,
              child: Opacity(
                opacity: _span(t, 0.15, 0.35),
                child: Transform.scale(scale: 0.7 + 0.3 * appear, child: child),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: center.dy + fullSize * 0.8 + 8,
              child: Transform.translate(
                offset: Offset(0, -24 * exit),
                child: _titleRow(t, fade),
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
      child: LayoutBuilder(
        builder: (context, constraints) => SplashPotato(
          size: constraints.biggest.shortestSide,
          intro: false,
          decorate: _decorate,
        ),
      ),
    );
  }

  /// The title fades in, colored from hot to cold.
  Widget _titleRow(double t, double fade) {
    final appear = _span(t, 0.9, 1.5);
    final opacity = Curves.easeOut.transform(appear) * fade;
    return Transform.translate(
      offset: Offset(0, 10 * (1 - Curves.easeOutCubic.transform(appear))),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        // Fades through the colors, an extra layer would stutter the exit
        shaderCallback: (rect) => LinearGradient(
          colors: [
            _fire[0].withValues(alpha: opacity),
            Colors.white.withValues(alpha: opacity),
            _ice[0].withValues(alpha: opacity),
          ],
          stops: const [0.1, 0.5, 0.9],
        ).createShader(rect),
        child: const Text(
          _title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SplashFxPainter extends CustomPainter {
  _SplashFxPainter({
    required this.center,
    required this.potatoSize,
    required this.t,
    required this.groove,
    required this.fade,
  });

  final Offset center;
  final double potatoSize;
  final double t;
  final double groove;
  final double fade;

  static const _beat = SplashStageState._beat;
  static const _fire = GameConstants.redColors;
  static const _ice = GameConstants.blueColors;

  /// Artboard units to screen pixels, see `SplashPotato`
  double get _scale => potatoSize * 1.45 / PotatoPainter.artboardSize;

  Offset _artboard(double x, double y) =>
      center + Offset(x - 250, y - 250) * _scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (groove <= 0) return;
    _paintNotes(canvas);
  }

  /// Every other beat a small note floats up out of an ear cup
  void _paintNotes(Canvas canvas) {
    const every = 2 * _beat;
    final n = (t / every).floor();
    for (var k = 0; k < 3; k++) {
      final i = n - k;
      final p = (t - i * every) / (every * 2.4);
      if (p < 0 || p > 1) continue;
      final left = i.isEven;
      final cup = left ? _artboard(80, 220) : _artboard(404, 220);
      final drift = Offset(
        (left ? -1 : 1) * (14 + 10 * p) + 6 * sin(p * 5),
        -70 * Curves.easeOut.transform(p),
      );
      final alpha = sin(p * pi).clamp(0.0, 1.0) * groove * fade;
      _drawNote(
        canvas,
        cup + drift,
        (left ? _fire : _ice)[0].withValues(alpha: alpha),
        size: potatoSize * 0.09,
      );
    }
  }

  static void _drawNote(
    Canvas canvas,
    Offset at,
    Color color, {
    required double size,
  }) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size * 1.3, height: size),
      paint,
    );
    canvas.restore();
    final stemX = at.dx + size * 0.55;
    canvas.drawRect(
      Rect.fromLTWH(
        stemX - size * 0.14,
        at.dy - size * 2.2,
        size * 0.28,
        size * 2.2,
      ),
      paint,
    );
    final flag = Path()
      ..moveTo(stemX, at.dy - size * 2.2)
      ..quadraticBezierTo(
        stemX + size * 1.1,
        at.dy - size * 1.6,
        stemX + size * 0.6,
        at.dy - size * 0.9,
      )
      ..quadraticBezierTo(
        stemX + size * 0.7,
        at.dy - size * 1.5,
        stemX,
        at.dy - size * 1.6,
      )
      ..close();
    canvas.drawPath(flag, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashFxPainter old) => true;
}
