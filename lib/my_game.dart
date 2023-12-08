import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class MyGame extends FlameGame<MyWorld>
    with PanDetector, HasCollisionDetection {
  MyGame()
      : super(
          world: MyWorld(),
          camera: CameraComponent.withFixedResolution(
            width: 800,
            height: 800,
          ),
        );

  @override
  void onPanStart(DragStartInfo info) => world._player.onPanStart(info);

  @override
  void onPanDown(DragDownInfo info) => world._player.onPanDown(info);

  @override
  void onPanUpdate(DragUpdateInfo info) => world._player.onPanUpdate(info);
}

class MyWorld extends World with HasGameRef<MyGame> {
  late Player _player;

  @override
  Future<void> onLoad() async {
    await add(_player = Player());
    add(TimerComponent(
      period: 3.0,
      repeat: true,
      onTick: _spawnSpawner,
    ));
  }

  void _spawnSpawner() {
    // final spawner = ParticleSpawner(
    //   position: Vector2(
    //         Random().nextDouble() * game.size.x,
    //         Random().nextDouble() * game.size.y,
    //       ) -
    //       game.size / 2,
    //   type: TemperatureType.values[Random().nextInt(2)],
    //   spawnInterval: 0.1,
    //   spawnCount: 10,
    // );
    // add(spawner);
  }
}

class Player extends PositionComponent with HasGameRef<MyGame> {
  Player({
    double size = 100,
  }) : super(
          size: Vector2.all(size),
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  late final Shield fireShield;
  late final Shield iceShield;

  double? panStartAngle;

  void onPanStart(DragStartInfo info) => _initPan(info.eventPosition.global);

  void onPanDown(DragDownInfo info) => _initPan(info.eventPosition.global);

  void _initPan(Vector2 touchGlobalPos) {
    final dir = game.camera.globalToLocal(touchGlobalPos) - position;
    panStartAngle = atan2(dir.x, dir.y);
  }

  void onPanUpdate(DragUpdateInfo info) {
    final dir = game.camera.globalToLocal(info.eventPosition.global) - position;
    fireShield.angle = (panStartAngle! - atan2(dir.x, dir.y)) * 1.5;
  }

  @override
  void onLoad() {
    super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
    add(fireShield = Shield(type: TemperatureType.hot));
    add(iceShield = Shield(type: TemperatureType.cold));
  }

  @override
  void update(double dt) {
    super.update(dt);
    iceShield.angle = fireShield.angle - pi;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset.zero + (size / 2).toOffset(),
      size.x / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white,
    );
  }
}

class Shield extends PositionComponent
    with ParentIsA<Player>, HasGameRef<MyGame> {
  Shield({
    required this.type,
    this.shieldWidth = 8.0,
    this.shieldSweep = pi / 2,
    this.offset = 4,
  }) : super(
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  final TemperatureType type;
  final double shieldWidth;
  final double shieldSweep;
  final double offset;

  @override
  void onLoad() {
    super.onLoad();
    size = parent.size + Vector2.all(shieldWidth * 2) + Vector2.all(offset * 2);
    position = parent.size / 2;
    _addHitbox();
  }

  void _addHitbox() {
    final center = size / 2;

    const precision = 8;

    final segment = shieldSweep / (precision - 1);
    final radius = size.x / 2;
    final startAngle = 0 - shieldSweep / 2;

    List<Vector2> vertices = [];
    for (int i = 0; i < precision; i++) {
      final thisSegment = startAngle + segment * i;
      vertices.add(
        center + Vector2(cos(thisSegment), sin(thisSegment)) * radius,
      );
    }

    for (int i = precision - 1; i >= 0; i--) {
      final thisSegment = startAngle + segment * i;
      vertices.add(
        center +
            Vector2(cos(thisSegment), sin(thisSegment)) *
                (radius - shieldWidth),
      );
    }

    add(PolygonHitbox(
      vertices,
      collisionType: CollisionType.passive,
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawArc(
      size.toRect().deflate(shieldWidth / 2),
      -shieldSweep / 2,
      shieldSweep,
      false,
      Paint()
        ..color = type.color
        ..strokeWidth = shieldWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
}

class ParticleSpawner extends PositionComponent with HasGameRef<MyGame> {
  ParticleSpawner({
    required super.position,
    required this.type,
    required this.spawnInterval,
    required this.spawnCount,
  });

  final double spawnInterval;
  final TemperatureType type;
  final int spawnCount;

  double _timeSinceLastSpawn = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawn();
    }
  }

  void _spawn() {
    game.world.add(
      ParticleElement(
        type: type,
        speed: 100,
        size: 10,
        target: game.world._player,
        position: position.clone(),
      ),
    );
  }
}

class ParticleElement extends PositionComponent with HasGameRef<MyGame> {
  ParticleElement({
    required this.type,
    required this.speed,
    required double size,
    required this.target,
    required super.position,
  }) : super(size: Vector2.all(size));

  final TemperatureType type;
  final double speed;
  final PositionComponent target;

  @override
  void update(double dt) {
    super.update(dt);
    final angle = atan2(
      target.position.y - position.y,
      target.position.x - position.x,
    );
    position += Vector2(cos(angle), sin(angle)) * speed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset.zero,
      size.x / 2,
      Paint()..color = type.color,
    );
  }
}

enum TemperatureType {
  hot,
  cold;

  TemperatureType get opposite => switch (this) {
        TemperatureType.hot => TemperatureType.cold,
        TemperatureType.cold => TemperatureType.hot,
      };

  Color get color => switch (this) {
        TemperatureType.hot => Colors.red,
        TemperatureType.cold => Colors.blue,
      };
}
