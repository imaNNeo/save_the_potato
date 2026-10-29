part of '../moving_components.dart';

sealed class MovingOrb extends MovingComponent {
  OrbType get type;

  List<Sprite> get smallSparkleSprites;

  List<Color> get colors => type.colors;

  int? _overrideCollisionSoundNumber;
  final _headPaint = Paint();

  int? getOverrideCollisionSoundNumber() {
    return _overrideCollisionSoundNumber;
  }

  double get trailSizeMultiplier => switch (type) {
    OrbType.fire => 0.85,
    OrbType.ice => 0.7,
  };

  VoidCallback? _onDisjointCallback;
  VoidCallback? _onPotatoHitCallback;

  /// Set once it got its speed, target and position (pooled orbs keep their
  /// old position until then)
  bool _initialized = false;

  /// Read and kept by [OrbEffects], which draws the tail and the glow
  bool get isFlying => _initialized && isMounted;
  Vector2 get direction => _direction;
  double effectsTime = 0;
  double sparkleClock = 0;
  double puffClock = 0;
  double moteClock = 0;
  double seed = 0;

  /// The head swells a little with it, the hitbox stays the same
  double pulse = 1;

  @override
  void initialize({
    required double speed,
    required PositionComponent target,
    required Vector2 position,
    double size = 22.0,
    VoidCallback? onDisjointCallback,
    VoidCallback? onPotatoHitCallback,
    int? overrideCollisionSoundNumber,
  }) {
    super.initialize(
      speed: speed,
      target: target,
      position: position,
      size: size,
    );
    _overrideCollisionSoundNumber = overrideCollisionSoundNumber;
    _onDisjointCallback = onDisjointCallback;
    _onPotatoHitCallback = onPotatoHitCallback;
    anchor = Anchor.center;
    effectsTime = 0;
    sparkleClock = 0;
    puffClock = 0;
    moteClock = 0;
    seed = rnd.nextDouble() * 100;
    pulse = 1;
    _initialized = true;
  }

  @override
  void onMount() {
    super.onMount();
    game.world.orbEffects.track(this);
  }

  @override
  void onRemove() {
    game.world.orbEffects.untrack(this);
    _initialized = false;
    super.onRemove();
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
    add(MovingOrbHead());
  }

  void _drawHead(Canvas canvas) {
    final offset = (size / 2).toOffset();
    final radius = size.x / 2 * pulse;
    canvas.drawCircle(offset, radius, _headPaint..color = colors.last);
  }

  /// Blocked by a shield, the shield shows the impact
  void disjoint() {
    _onDisjointCallback?.call();
  }

  void onPotatoHit() {
    _onPotatoHitCallback?.call();
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
