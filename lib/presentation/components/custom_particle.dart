import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'component_pool.dart';

typedef CustomParticleRenderDelegate = void Function(
  Canvas canvas,
  Paint overridePaint,
  CustomParticle particle,
);

class CustomParticle extends PositionComponent {
  final _overridePaint = Paint();

  Timer? _progressTimer;

  double get progress => _progressTimer?.progress ?? 0.0;

  late Vector2 acceleration;

  late Vector2 speed;

  late CustomParticleRenderDelegate renderDelegate;

  void startParticle({
    required double lifespan,
    required ComponentPool pool,
    required CustomParticleRenderDelegate renderDelegate,
    Vector2? acceleration,
    Vector2? speed,
    Vector2? position,
    Anchor? anchor,
    int? priority,
    Vector2? size,
    double? angle,
  }) {
    _progressTimer?.stop();
    _progressTimer = Timer(
      lifespan,
      onTick: () {
        _progressTimer?.stop();
        _progressTimer = null;
        pool.release(this);
      },
    )..start();
    this.acceleration = acceleration ?? Vector2.zero();
    this.speed = speed ?? Vector2.zero();
    this.renderDelegate = renderDelegate;
    this.position = position ?? Vector2.zero();
    this.anchor = anchor ?? Anchor.center;
    this.priority = priority ?? 0;
    this.size = size ?? Vector2.all(32);
    this.angle = angle ?? 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _progressTimer?.update(dt);
    position += acceleration * dt;
    speed.addScaled(acceleration, dt);
    position
      ..addScaled(speed, dt)
      ..addScaled(acceleration, -dt * dt * 0.5);
  }

  @override
  void render(Canvas canvas) {
    renderDelegate(canvas, _overridePaint, this);
  }
}
