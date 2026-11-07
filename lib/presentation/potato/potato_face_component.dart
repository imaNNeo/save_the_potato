import 'dart:ui';

import 'package:flame/components.dart';

import 'potato_animator.dart';
import 'potato_painter.dart';
import 'potato_pose.dart';
import 'dizzy_face.dart';

/// Draws the code-drawn potato in the game and plays its animations.
///
/// Tell [animator] what happened (hit, scared, ...) and it takes care of the
/// rest. [dizzy] adds the dizzy face while it recovers from a hit.
class PotatoFaceComponent extends PositionComponent {
  PotatoFaceComponent({
    required this.animator,
    this.dizzy,
    super.position,
    double size = 152,
  }) : super(size: Vector2.all(size), anchor: Anchor.center);

  final PotatoAnimator animator;
  final DizzyFace? dizzy;
  final _pose = PotatoPose();

  @override
  void update(double dt) {
    super.update(dt);
    animator.update(dt);
    dizzy?.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final dizzy = this.dizzy;
    if (dizzy == null || !dizzy.isActive) {
      PotatoPainter.paintFitted(canvas, animator.pose, boxSize: size.x);
      return;
    }
    _pose.copyFrom(animator.pose);
    dizzy.apply(_pose);
    canvas.save();
    canvas.scale(size.x / PotatoPainter.artboardSize);
    dizzy.transform(canvas);
    PotatoPainter.paint(canvas, _pose);
    dizzy.paintOver(canvas, headphones: _pose[PotatoProp.headphones]);
    canvas.restore();
  }
}
