import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:save_the_potato/presentation/potato/potato_animator.dart';
import 'package:save_the_potato/presentation/potato/potato_painter.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';

/// The code-drawn potato as a Flutter widget, used on the splash screen.
///
/// With [intro] it plays the intro once (sparkles pop in, it looks left and
/// right), then keeps idling. Without it, it starts idling right away.
/// It is drawn on the first frame, there is nothing to load.
class SplashPotato extends StatefulWidget {
  const SplashPotato({
    super.key,
    this.size = 300,
    this.intro = true,
    this.decorate,
  });

  final double size;
  final bool intro;

  /// Called every frame after the animation, to add moves of its own on top
  /// (headphones, dancing). [seconds] is the time since the potato appeared.
  final void Function(PotatoPose pose, double seconds)? decorate;

  /// How much bigger than its box the potato is drawn, as before.
  static const _drawScale = 1.45;

  /// In the game the potato is drawn in a box 1.52 times the Potato
  /// component's size (152 world units for a 100 unit potato).
  static const _gameDrawScale = 1.52;

  /// The [size] that makes this widget look exactly like the game potato,
  /// when the Potato component is [gamePotatoScreenSize] pixels on screen.
  static double sizeForGamePotato(double gamePotatoScreenSize) =>
      gamePotatoScreenSize * _gameDrawScale / _drawScale;

  @override
  State<SplashPotato> createState() => _SplashPotatoState();
}

class _SplashPotatoState extends State<SplashPotato>
    with SingleTickerProviderStateMixin {
  late final PotatoAnimator _animator = PotatoAnimator(intro: widget.intro);
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt =
        (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;
    _animator.update(dt);
    widget.decorate?.call(
      _animator.pose,
      elapsed.inMicroseconds / Duration.microsecondsPerSecond,
    );
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: _PotatoWidgetPainter(_animator, _frame)),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }
}

class _PotatoWidgetPainter extends CustomPainter {
  _PotatoWidgetPainter(this.animator, Listenable repaint)
    : super(repaint: repaint);

  final PotatoAnimator animator;

  @override
  void paint(Canvas canvas, Size size) {
    final box = size.shortestSide * SplashPotato._drawScale;
    PotatoPainter.paintFitted(
      canvas,
      animator.pose,
      boxSize: box,
      offset: Offset((size.width - box) / 2, (size.height - box) / 2),
    );
  }

  @override
  bool shouldRepaint(_PotatoWidgetPainter oldDelegate) =>
      oldDelegate.animator != animator;
}
