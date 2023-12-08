import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'my_game.dart';

class ElementSpawner extends PositionComponent with HasGameRef<MyGame> {
  ElementSpawner({
    required super.position,
    required this.type,
    required this.spawnInterval,
    required this.spawnCount,
  });

  final double spawnInterval;
  final TemperatureType type;
  final int spawnCount;

  double _timeSinceLastSpawn = 0;
  int spawned = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= spawnInterval) {
      _timeSinceLastSpawn = 0;
      _spawn();
    }
    if (spawned >= spawnCount) {
      removeFromParent();
    }
  }

  void _spawn() {
    spawned++;
    const speedMin = 80;
    const speedMax = 150;
    game.world.add(
      ElementParticle(
        type: type,
        speed: Random().nextDouble() * (speedMax - speedMin) + speedMin,
        size: 20,
        target: game.world.player,
        position: position.clone(),
      ),
    );
  }
}

class ElementParticle extends PositionComponent with HasGameRef<MyGame> {
  ElementParticle({
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
  void onLoad() {
    super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

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
      (size / 2).toOffset(),
      size.x / 2,
      Paint()..color = type.color,
    );
  }
}
