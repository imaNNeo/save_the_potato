part of '../moving_components.dart';

class MovingOrb extends MovingComponent {
  MovingOrb({
    required this.type,
    required super.speed,
    required super.size,
    required super.target,
    required super.position,
  });

  final ColorType type;

  late Paint _headPaint;

  late List<Sprite> smallSparkleSprites;

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
    smallSparkleSprites = await Future.wait(
      List.generate(2, (i) => Sprite.load('snow/snowflake${i + 1}.png')),
    );
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

  void disjoint() {
    removeFromParent();
    add(OrbDisjointParticleComponent(
      colors: colors,
      smallSparkleSprites: smallSparkleSprites,
    ));
  }
}
