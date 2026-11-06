import 'dart:ui';

import 'package:flame/components.dart';

import 'potato_animator.dart';
import 'potato_painter.dart';
import 'potato_pose.dart';
import 'recovery_face.dart';

/// Draws the code-drawn potato in the game and plays its animations.
///
/// Tell [animator] what happened (hit, scared, ...) and it takes care of the
/// rest. [recovery] adds a face for the moments after a hit.
class PotatoFaceComponent extends PositionComponent {
  PotatoFaceComponent({
    required this.animator,
    this.recovery,
    super.position,
    double size = 152,
  }) : super(size: Vector2.all(size), anchor: Anchor.center);

  final PotatoAnimator animator;
  final RecoveryFace? recovery;
  final _pose = PotatoPose();

  @override
  void update(double dt) {
    super.update(dt);
    animator.update(dt);
    recovery?.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final recovery = this.recovery;
    if (recovery == null || !recovery.isActive) {
      PotatoPainter.paintFitted(canvas, animator.pose, boxSize: size.x);
      return;
    }
    _pose.copyFrom(animator.pose);
    recovery.apply(_pose);
    canvas.save();
    canvas.scale(size.x / PotatoPainter.artboardSize);
    recovery.transform(canvas);
    PotatoPainter.paint(canvas, _pose);
    recovery.paintOver(canvas, _pose);
    canvas.restore();
  }
}
