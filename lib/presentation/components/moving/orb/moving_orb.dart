part of '../moving_components.dart';

sealed class MovingOrb extends MovingComponent {
  OrbType get type;

  List<Sprite> get smallSparkleSprites;

  List<Color> get colors => type.colors;

  int? _overrideCollisionSoundNumber;

  int? getOverrideCollisionSoundNumber() {
    return _overrideCollisionSoundNumber;
  }

  /// Set by the rhythm modes right after [initialize]
  RhythmHit? rhythmHit;

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
    double size = 17.0,
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
    rhythmHit = null;
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
  }

  /// A glowing core with little white, fading softly into its glow, with a
  /// slowly turning crystal in it. Fire and ice look the same, each in its
  /// own colors. Drawn at unit size and scaled, so the gradients are made
  /// once per orb type.
  void _drawHead(Canvas canvas) {
    final style = _OrbHeadStyle.of(type);
    final t = effectsTime + seed;
    canvas
      ..save()
      ..translate(size.x / 2, size.y / 2)
      ..scale(size.x / 2 * 1.1 * pulse)
      ..drawCircle(Offset.zero, 1, style.body);
    _drawCoreBlob(canvas, style, 0, 0, 0.62 + 0.05 * sin(t * 4.5));
    // Six spokes of a crystal
    final angle = t * 0.8;
    for (var i = 0; i < 3; i++) {
      final a = angle + i * pi / 3;
      final x = cos(a) * 0.6, y = sin(a) * 0.6;
      canvas.drawLine(Offset(x, y), Offset(-x, -y), style.crystal);
    }
    canvas.restore();
  }

  void _drawCoreBlob(
    Canvas canvas,
    _OrbHeadStyle style,
    double x,
    double y,
    double radius,
  ) {
    canvas
      ..save()
      ..translate(x, y)
      ..scale(radius)
      ..drawCircle(Offset.zero, 1, style.core)
      ..restore();
  }

  /// Blocked by a shield, the shield shows the impact
  void disjoint() {
    _onDisjointCallback?.call();
  }

  void onPotatoHit() {
    _onPotatoHitCallback?.call();
  }
}

/// The paints of an orb's head, at unit size around the origin
class _OrbHeadStyle {
  _OrbHeadStyle(List<Color> colors)
    : body = Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          1,
          [
            Color.lerp(colors[0], const Color(0xFFFFFFFF), 0.5)!,
            colors[0],
            colors[1],
            colors[2],
            colors[2].withValues(alpha: 0),
          ],
          [0.0, 0.28, 0.58, 0.82, 1.0],
        ),
      core = Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          Offset.zero,
          1,
          [
            const Color(0x8CFFFFFF),
            colors[0].withValues(alpha: 0.4),
            colors[0].withValues(alpha: 0),
          ],
          [0.0, 0.45, 1.0],
        ),
      crystal = Paint()
        ..blendMode = BlendMode.plus
        ..color = colors[0].withValues(alpha: 0.5)
        ..strokeWidth = 0.1
        ..strokeCap = StrokeCap.round;

  static final _styles = {
    for (final type in OrbType.values) type: _OrbHeadStyle(type.colors),
  };

  static _OrbHeadStyle of(OrbType type) => _styles[type]!;

  final Paint body, core, crystal;
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
