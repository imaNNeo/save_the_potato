import 'dart:ui';

import 'package:flame/components.dart';
import 'package:save_the_potato/domain/hit_invincibility.dart';

/// Draws its children with the opacity of [invincibility], so whatever draws
/// the potato (the Rive file today, code later) blinks while it's safe.
///
/// The shields aren't inside it, so they never blink.
class HitBlink extends PositionComponent {
  HitBlink({required this.invincibility, super.size, super.position})
    : super(anchor: Anchor.center);

  final HitInvincibility invincibility;
  final _paint = Paint();

  @override
  void renderTree(Canvas canvas) {
    final opacity = invincibility.opacity;
    if (opacity >= 1) {
      super.renderTree(canvas);
      return;
    }
    _paint.color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.saveLayer(null, _paint);
    super.renderTree(canvas);
    canvas.restore();
  }
}
