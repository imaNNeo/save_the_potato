import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:save_the_potato/presentation/background_reactions.dart';

/// Renders the moving stars background (`shaders/background.frag`) and
/// animates its colors when they change.
class AnimatedBackgroundStars extends ImplicitlyAnimatedWidget {
  const AnimatedBackgroundStars({
    super.key,
    required this.backgroundColor,
    required this.starsColor,
    required this.starsTimeScale,
    required this.starsSize,
    this.reactions,
    super.duration = const Duration(milliseconds: 300),
  });

  final Color backgroundColor;
  final Color starsColor;
  final double starsTimeScale;
  final double starsSize;
  final BackgroundReactions? reactions;

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
      reactions: widget.reactions,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _backgroundColor = visitor(
      _backgroundColor,
      widget.backgroundColor,
      (dynamic value) => ColorTween(begin: value as Color),
    ) as ColorTween?;
    _starsColor = visitor(
      _starsColor,
      widget.starsColor,
      (dynamic value) => ColorTween(begin: value as Color),
    ) as ColorTween?;
  }
}

/// [timeScale] is how fast the stars move, `0.0` freezes them. While frozen
/// no frames are scheduled and nothing is repainted, unless the
/// [reactions] to the game are still playing out.
class BackgroundStars extends StatefulWidget {
  const BackgroundStars({
    super.key,
    required this.backgroundColor,
    required this.timeScale,
    this.starsColor = Colors.white,
    required this.starsSize,
    this.reactions,
  });

  final Color backgroundColor;
  final Color starsColor;
  final double timeScale;
  final double starsSize;
  final BackgroundReactions? reactions;

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
    _time.value += dt * widget.timeScale * (widget.reactions?.speedBoost ?? 1);
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
          reactions: widget.reactions,
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
    required this.reactions,
  }) : super(
         repaint: reactions == null
             ? time
             : Listenable.merge([time, reactions]),
       );

  final FragmentShader shader;
  final ValueNotifier<double> time;
  final Color backgroundColor;
  final Color starsColor;
  final double starsSize;
  final BackgroundReactions? reactions;

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
    _setReactions(reactions ?? _noReactions);
    canvas.drawRect(Offset.zero & size, _paint..shader = shader);
  }

  static final _noReactions = BackgroundReactions();

  void _setReactions(BackgroundReactions reactions) {
    shader
      ..setFloat(10, reactions.heat)
      ..setFloat(11, reactions.stretch)
      ..setFloat(12, reactions.hit)
      ..setFloat(13, reactions.tension)
      ..setFloat(14, reactions.shakeX)
      ..setFloat(15, reactions.shakeY)
      ..setFloat(16, reactions.glowR)
      ..setFloat(17, reactions.glowG)
      ..setFloat(18, reactions.glowB)
      ..setFloat(19, reactions.flash);
    var i = 20;
    for (final wave in reactions.waves) {
      final intensity = wave.intensity;
      final focus = wave.focus;
      shader
        ..setFloat(i++, wave.radius)
        ..setFloat(i++, intensity > 0 ? 1 / wave.halfWidth : 0)
        ..setFloat(i++, wave.dirX * focus)
        ..setFloat(i++, wave.dirY * focus)
        ..setFloat(i++, wave.r * intensity)
        ..setFloat(i++, wave.g * intensity)
        ..setFloat(i++, wave.b * intensity)
        ..setFloat(i++, 1 - focus);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundStarsPainter oldDelegate) =>
      oldDelegate.reactions != reactions ||
      oldDelegate.shader != shader ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.starsColor != starsColor ||
      oldDelegate.starsSize != starsSize;
}
