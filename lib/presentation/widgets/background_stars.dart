import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Renders the moving stars background (`shaders/background.frag`) and
/// animates its colors when they change.
class AnimatedBackgroundStars extends ImplicitlyAnimatedWidget {
  const AnimatedBackgroundStars({
    super.key,
    required this.backgroundColor,
    required this.starsColor,
    required this.starsTimeScale,
    required this.starsSize,
    super.duration = const Duration(milliseconds: 300),
  });

  final Color backgroundColor;
  final Color starsColor;
  final double starsTimeScale;
  final double starsSize;

  @override
  AnimatedWidgetBaseState<AnimatedBackgroundStars> createState() =>
      _AnimatedBackgroundStarsState();
}

class _AnimatedBackgroundStarsState
    extends AnimatedWidgetBaseState<AnimatedBackgroundStars> {
  ColorTween? _backgroundColor;
  ColorTween? _starsColor;

  @override
  Widget build(BuildContext context) {
    return BackgroundStars(
      backgroundColor: _backgroundColor?.evaluate(animation) ?? Colors.black,
      starsColor: _starsColor?.evaluate(animation) ?? Colors.white,
      timeScale: widget.starsTimeScale,
      starsSize: widget.starsSize,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _backgroundColor =
        visitor(
              _backgroundColor,
              widget.backgroundColor,
              (dynamic value) => ColorTween(begin: value as Color),
            )
            as ColorTween?;
    _starsColor =
        visitor(
              _starsColor,
              widget.starsColor,
              (dynamic value) => ColorTween(begin: value as Color),
            )
            as ColorTween?;
  }
}

/// [timeScale] is how fast the stars move, `0.0` freezes them. While frozen
/// no frames are scheduled and nothing is repainted.
class BackgroundStars extends StatefulWidget {
  const BackgroundStars({
    super.key,
    required this.backgroundColor,
    required this.timeScale,
    this.starsColor = Colors.white,
    required this.starsSize,
  });

  final Color backgroundColor;
  final Color starsColor;
  final double timeScale;
  final double starsSize;

  @override
  State<BackgroundStars> createState() => _BackgroundStarsState();
}

class _BackgroundStarsState extends State<BackgroundStars>
    with SingleTickerProviderStateMixin {
  static Future<FragmentProgram>? _program;

  /// Warm-up time, so the stars are already spread out on the first frame.
  static const _initialTime = 1000.0;

  FragmentShader? _shader;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Shader time, only repaints the painter (no rebuilds) when it changes.
  final _time = ValueNotifier<double>(_initialTime);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _program ??= FragmentProgram.fromAsset('shaders/background.frag');
    _program!.then((program) {
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
      _updateTicker();
    }, onError: (Object e) => debugPrint('Background stars disabled: $e'));
  }

  @override
  void didUpdateWidget(covariant BackgroundStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTicker();
  }

  void _updateTicker() {
    final shouldTick = _shader != null && widget.timeScale > 0;
    if (shouldTick && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldTick && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000;
    _lastElapsed = elapsed;
    _time.value += dt * widget.timeScale;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) {
      return const SizedBox.expand();
    }
    // Isolate the stars in their own layer, so the game repainting on top
    // doesn't repaint them and vice versa.
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _BackgroundStarsPainter(
          shader: shader,
          time: _time,
          backgroundColor: widget.backgroundColor,
          starsColor: widget.starsColor,
          starsSize: widget.starsSize,
        ),
      ),
    );
  }
}

class _BackgroundStarsPainter extends CustomPainter {
  _BackgroundStarsPainter({
    required this.shader,
    required this.time,
    required this.backgroundColor,
    required this.starsColor,
    required this.starsSize,
  }) : super(repaint: time);

  final FragmentShader shader;
  final ValueNotifier<double> time;
  final Color backgroundColor;
  final Color starsColor;
  final double starsSize;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, time.value)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height)
      ..setFloat(3, backgroundColor.r)
      ..setFloat(4, backgroundColor.g)
      ..setFloat(5, backgroundColor.b)
      ..setFloat(6, starsColor.r)
      ..setFloat(7, starsColor.g)
      ..setFloat(8, starsColor.b)
      ..setFloat(9, starsSize);
    canvas.drawRect(Offset.zero & size, _paint..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _BackgroundStarsPainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.starsColor != starsColor ||
      oldDelegate.starsSize != starsSize;
}
