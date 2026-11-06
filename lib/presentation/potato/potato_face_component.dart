import 'dart:ui';

import 'package:flame/components.dart';

import 'potato_animator.dart';
import 'potato_painter.dart';

/// Draws the code-drawn potato in the game and plays its animations.
///
/// Tell [animator] what happened (hit, scared, ...) and it takes care of the
/// rest.
class PotatoFaceComponent extends PositionComponent {
  PotatoFaceComponent({
    required this.animator,
    super.position,
    double size = 152,
  }) : super(size: Vector2.all(size), anchor: Anchor.center);

  final PotatoAnimator animator;

  @override
  void update(double dt) {
    super.update(dt);
    animator.update(dt);
  }

  @override
  void render(Canvas canvas) {
    PotatoPainter.paintFitted(canvas, animator.pose, boxSize: size.x);
  }
}
