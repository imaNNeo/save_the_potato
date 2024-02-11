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

  List<Color> get colors => GameConstants.pinkColors;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
    heartSprite1 = await Sprite.load('heart/heart1.png');
    heartSprite2 = await Sprite.load('heart/heart2.png');
    final radius = (min(size.x, size.y) / 2);
    add(CircleHitbox(
      collisionType: CollisionType.passive,
      radius: radius * 0.6,
      anchor: Anchor.center,
      position: size / 2,
    ));
  }

  @override
  void update(double dt) {
    angle += (pi / 2) * dt;
    super.update(dt);
  }


  @override
  void render(Canvas canvas) {
    heartSprite1.render(
      canvas,
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      overridePaint: Paint()
        ..colorFilter = ColorFilter.mode(
          colors.last,
          BlendMode.srcIn,
        ),
    );
    heartSprite2.render(
      canvas,
      size: size * 1.2,
      anchor: Anchor.center,
      position: size / 2,
      overridePaint: Paint()
        ..colorFilter = const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
    );
  }

  void disjoint() {
    getIt.get<AnalyticsHelper>().heartDisjointed();
    removeFromParent();
    add(HealthDisjointParticleComponent(
      colors: [...colors, Colors.white],
      smallSparkleSprites: [
        heartSprite1,
        heartSprite2,
      ],
    ));
  }
}
