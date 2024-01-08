import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

class PotatoIdle extends StatelessWidget {
  const PotatoIdle({
    super.key,
    this.size = 300,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: 1.45,
        child: const RiveAnimation.asset(
          'assets/rive/potato.riv',
          stateMachines: ["State Machine 1"],
        ),
      ),
    );
  }
}
