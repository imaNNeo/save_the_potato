part of '../moving_components.dart';

class MovingHealth extends MovingComponent {
  MovingHealth();

  late Sprite heartSprite1, heartSprite2;

  double rotation = 0;

  List<Color> get colors => GameConstants.pinkColors;

  VoidCallback? _onDisjointCallback;

  late CircleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
    heartSprite1 = await Sprite.load('heart/heart1.png');
    heartSprite2 = await Sprite.load('heart/heart2.png');
    add(_hitbox = CircleHitbox());
  }

  @override
  void initialize({
    required double speed,
    required PositionComponent target,
    required Vector2 position,
    required double size,
    VoidCallback? onDisjointCallback,
  }) {
    super.initialize(
      speed: speed,
      target: target,
      position: position,
      size: size,
    );

    final radius = size / 2;
    _hitbox
      ..collisionType = CollisionType.passive
      ..radius = radius * 0.8
      ..anchor = Anchor.center
      ..position = super.size / 2;

    _onDisjointCallback = onDisjointCallback!;
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
    _onDisjointCallback?.call();
    add(HealthDisjointParticleComponent(
      colors: [...colors, Colors.white],
      smallSparkleSprites: [
        heartSprite1,
        heartSprite2,
      ],
    ));
  }
}
