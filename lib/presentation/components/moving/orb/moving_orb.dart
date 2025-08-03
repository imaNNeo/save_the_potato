part of '../moving_components.dart';

sealed class MovingOrb extends MovingComponent {
  OrbType get type;

  List<Sprite> get smallSparkleSprites;

  List<Color> get colors => type.colors;

  int? overrideCollisionSoundNumber;

  double get trailSizeMultiplier => switch(type) {
    OrbType.fire => 0.85,
    OrbType.ice => 0.7,
  };

  VoidCallback? _onDisjointCallback;

  late MovingOrbTailParticles _movingOrbTailParticles;

  @override
  void initialize({
    required double speed,
    required PositionComponent target,
    required Vector2 position,
    double size = 22.0,
    ComponentPool<CustomParticle>? movingTrailParticlePool,
    VoidCallback? onDisjoint,
  }) {
    super.initialize(
      speed: speed,
      target: target,
      position: position,
      size: size,
    );
    _movingOrbTailParticles.particlePool = movingTrailParticlePool!;
    _onDisjointCallback = onDisjoint;
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawHead(canvas);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
    add(_movingOrbTailParticles = MovingOrbTailParticles());
    add(MovingOrbHead());
  }

  void _drawHead(Canvas canvas) {
    final offset = (size / 2).toOffset();
    final radius = size.x / 2;
    canvas.drawCircle(
      offset,
      radius,
      Paint()
        ..color = colors.last.withValues(alpha: 1)
        ..maskFilter = null,
    );
  }

  void disjoint(double contactAngle) {
    _onDisjointCallback?.call();
    add(OrbDisjointParticleComponent(
      orbType: type,
      colors: colors,
      smallSparkleSprites: smallSparkleSprites,
      speedProgress: bloc.state.difficulty,
      contactAngle: contactAngle,
    ));
  }
}

class FireOrb extends MovingOrb {
  FireOrb();

  late List<Sprite> _smallSparkleSprites;

  @override
  List<Sprite> get smallSparkleSprites => _smallSparkleSprites;

  @override
  OrbType get type => OrbType.fire;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _smallSparkleSprites = await Future.wait(
      List.generate(2, (i) => Sprite.load('sparkle/sparkle${i + 1}.png')),
    );
  }
}

class IceOrb extends MovingOrb {
  IceOrb();

  late List<Sprite> _smallSparkleSprites;

  @override
  List<Sprite> get smallSparkleSprites => _smallSparkleSprites;

  @override
  OrbType get type => OrbType.ice;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _smallSparkleSprites = await Future.wait(
      List.generate(2, (i) => Sprite.load('snow/snowflake${i + 1}.png')),
    );
  }
}
