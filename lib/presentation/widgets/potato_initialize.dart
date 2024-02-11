import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

class SplashPotato extends StatefulWidget {
  const SplashPotato({
    super.key,
    this.size = 300,
  });
  final double size;

  @override
  State<SplashPotato> createState() => _SplashPotatoState();
}

class _SplashPotatoState extends State<SplashPotato> {
  /// Controller for playback
  late RiveAnimationController _controller;

  @override
  void initState() {
    _controller = OneShotAnimation(
      'Initialize',
      autoplay: true,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Transform.scale(
        scale: 1.45,
        child: RiveAnimation.asset(
          'assets/rive/potato.riv',
          controllers: [_controller],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
