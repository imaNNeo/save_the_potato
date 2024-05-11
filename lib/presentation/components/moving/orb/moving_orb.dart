part of '../moving_components.dart';

sealed class MovingOrb extends MovingComponent {
  MovingOrb({
    required super.speed,
    required super.size,
    required super.target,
    required super.position,
  });

  OrbType get type;

  late Paint _headPaint;

  List<Sprite> get smallSparkleSprites;

  List<Color> get colors => type.colors;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawHead(canvas);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _headPaint = Paint();
    add(CircleHitbox(collisionType: CollisionType.passive));
    add(MovingOrbTailParticles());
  }

  void _drawHead(Canvas canvas) {
    final offset = (size / 2).toOffset();
    final radius = size.x / 2;
    canvas.drawCircle(
      offset,
      radius,
      _headPaint
        ..color = colors.last.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    canvas.drawCircle(
      offset,
      radius,
      _headPaint
        ..color = colors.last.withOpacity(1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    canvas.drawCircle(
      offset,
      radius,
      _headPaint
        ..color = colors.last.withOpacity(1)
        ..maskFilter = null,
    );
    canvas.drawCircle(
      offset,
      radius * 0.75,
      _headPaint
        ..color = Colors.white.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void disjoint(double contactAngle) {
    removeFromParent();
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
  FireOrb({
    required super.speed,
    required super.size,
    required super.target,
    required super.position,
  });

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
  IceOrb({
    required super.speed,
    required super.size,
    required super.target,
    required super.position,
  });

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
