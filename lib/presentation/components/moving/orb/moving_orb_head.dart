import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';

class MovingOrbHead extends PositionComponent with ParentIsA<MovingOrb> {
  late Sprite _sprite1Glow, _sprite2Main, _sprite3Shine;
  late Paint _paint;

  MovingOrbHead();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite1Glow = await Sprite.load('orb/orb-1-glow.png');
    _sprite2Main = await Sprite.load('orb/orb-2-main-circle.png');
    _sprite3Shine = await Sprite.load('orb/orb-3-shine.png');
    anchor = Anchor.center;
    size = Vector2.all(parent.size.x * 2);
    position = parent.size / 2;
    _paint = Paint();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final offset = (size / 2).toOffset();
    _sprite1Glow.render(
      canvas,
      size: size,
      anchor: Anchor.center,
      position: offset.toVector2(),
      overridePaint: _paint
        ..colorFilter = ColorFilter.mode(
          parent.colors[1].withOpacity(0.8),
          BlendMode.srcIn,
        ),
    );
    _sprite2Main.render(
      canvas,
      size: size,
      anchor: Anchor.center,
      position: offset.toVector2(),
      overridePaint: _paint
        ..colorFilter = ColorFilter.mode(
          parent.colors[1],
          BlendMode.srcIn,
        ),
    );
    _sprite3Shine.render(
      canvas,
      size: size,
      anchor: Anchor.center,
      position: offset.toVector2(),
    );
  }
}
