import 'dart:ui';

import 'package:flutter/material.dart';

import 'shaders/shader_renderer.dart';

class AnimatedBackgroundStars extends ImplicitlyAnimatedWidget {
  final Color backgroundColor;
  final Color starsColor;
  final double starsTimeScale;
  final double starsSize;

  const AnimatedBackgroundStars({
    super.key,
    required this.backgroundColor,
    required this.starsColor,
    required this.starsTimeScale,
    required this.starsSize,
    super.duration = const Duration(milliseconds: 300),
  });

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
    final Animation<double> animation = this.animation;
    return BackgroundStars(
      backgroundColor: _backgroundColor?.evaluate(animation) ?? Colors.black,
      starColor: _starsColor?.evaluate(animation) ?? Colors.white,
      timeScale: widget.starsTimeScale,
      starsSize: widget.starsSize,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _backgroundColor = visitor(_backgroundColor, widget.backgroundColor,
        (dynamic value) => ColorTween(begin: value as Color)) as ColorTween?;
    _starsColor = visitor(_starsColor, widget.starsColor,
        (dynamic value) => ColorTween(begin: value as Color)) as ColorTween?;
  }
}

class BackgroundStars extends StatefulWidget {
  const BackgroundStars({
    super.key,
    required this.backgroundColor,
    required this.timeScale,
    this.starColor = Colors.white,
    required this.starsSize,
  });

  final Color backgroundColor;
  final Color starColor;
  final double timeScale;
  final double starsSize;

  @override
  State<BackgroundStars> createState() => _BackgroundStarsState();
}

class _BackgroundStarsState extends State<BackgroundStars> {
  FragmentShader? _backgroundShader;

  @override
  void initState() {
    asyncInit();
    super.initState();
  }

  void asyncInit() async {
    final program = await FragmentProgram.fromAsset('shaders/background.frag');
    setState(() {
      _backgroundShader = program.fragmentShader();
      _refreshShaderParams();
    });
  }

  @override
  void didUpdateWidget(covariant BackgroundStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshShaderParams();
  }

  void _refreshShaderParams() {
    _backgroundShader?.setFloat(3, widget.backgroundColor.r);
    _backgroundShader?.setFloat(4, widget.backgroundColor.g);
    _backgroundShader?.setFloat(5, widget.backgroundColor.b);

    _backgroundShader?.setFloat(6, widget.starColor.r);
    _backgroundShader?.setFloat(7, widget.starColor.g);
    _backgroundShader?.setFloat(8, widget.starColor.b);
    _backgroundShader?.setFloat(9, widget.starsSize);
  }

  @override
  Widget build(BuildContext context) {
    if (_backgroundShader == null) {
      return const SizedBox();
    }
    return ShaderRendererWidget(
      shader: _backgroundShader!,
      initialTimeOffset: 1000.0,
      timeScale: widget.timeScale,
    );
  }
}
