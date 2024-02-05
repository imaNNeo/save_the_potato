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

  late Paint _disjointParticlePaint;

  double get radius => size.x / 2;

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
    _disjointParticlePaint = Paint();
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
    final color = colors.random();
    final randomOrder = colors.randomOrder();
    TweenSequence<Color?> colorTween = TweenSequence<Color?>([
      for (int i = 0; i < randomOrder.length - 1; i++)
        TweenSequenceItem(
          weight: 1,
          tween: ColorTween(
            begin: randomOrder[i],
            end: randomOrder[i + 1],
          ),
        ),
    ]);
    game.world.add(ParticleSystemComponent(
      position: positionOfAnchor(Anchor.center),
      anchor: Anchor.center,
      particle: Particle.generate(
        count: 30,
        lifespan: 2,
        generator: (i) {
          final sprite = smallSparkleSprites.random();
          return AcceleratedParticle(
            speed: Vector2(
              (rnd.nextDouble() * 200) - 100,
              (rnd.nextDouble() * 200) - 100,
            ),
            acceleration: Vector2(
              (rnd.nextDouble() * 200) - 100,
              (rnd.nextDouble() * 200) - 100,
            ),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = Tween(begin: 0.8, end: 0.0)
                    .chain(CurveTween(curve: Curves.easeOutCubic))
                    .transform(particle.progress);
                if (opacity <= 0.01) {
                  return;
                }
                if (i % 3 == 0) {
                  canvas.drawCircle(
                    Offset.zero,
                    (radius * 0.6) * (1 - particle.progress),
                    _disjointParticlePaint
                      ..colorFilter = null
                      ..maskFilter = null
                      ..color = (rnd.nextBool()
                              ? color
                              : colorTween.transform(particle.progress))!
                          .withOpacity(opacity),
                  );
                } else {
                  sprite.render(
                    canvas,
                    size: Vector2.all((size.x * 1.2) * (1 - particle.progress)),
                    anchor: Anchor.center,
                    overridePaint: _disjointParticlePaint
                      ..colorFilter = ColorFilter.mode(
                        (rnd.nextBool()
                                ? color
                                : colorTween.transform(particle.progress))!
                            .withOpacity(opacity),
                        BlendMode.srcIn,
                      )
                      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
                  );
                }
              },
            ),
          );
        },
      ),
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
