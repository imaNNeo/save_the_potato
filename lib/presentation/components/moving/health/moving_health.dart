part of '../moving_components.dart';

class MovingHealth extends MovingComponent {
  MovingHealth({
    required super.speed,
    required super.size,
    required super.target,
    required super.position,
  });

  late Sprite heartSprite1, heartSprite2;

  double rotation = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    heartSprite1 = await Sprite.load('heart/heart1.png');
    heartSprite2 = await Sprite.load('heart/heart2.png');
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    rotation += dt * 2;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(rotation);
    heartSprite1.render(
      canvas,
      size: size,
      anchor: Anchor.center,
      overridePaint: Paint()
        ..colorFilter = ColorFilter.mode(
          GameConstants.pinkColors.last,
          BlendMode.srcIn,
        ),
    );
    heartSprite2.render(
      canvas,
      size: size * 1.2,
      anchor: Anchor.center,
      overridePaint: Paint()
        ..colorFilter = const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
    );
    canvas.translate(0, 0);
  }

  void disjoint() {
    removeFromParent();
  }
}
