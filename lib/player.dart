import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'element.dart';
import 'my_game.dart';

class Player extends PositionComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
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
    add(CircleHitbox(collisionType: CollisionType.active));
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

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Element) {
      other.removeFromParent();
    }
  }
}

class Shield extends PositionComponent
    with ParentIsA<Player>, HasGameRef<MyGame>, CollisionCallbacks {
  Shield({
    required this.type,
    this.shieldWidth = 6.0,
    this.shieldSweep = pi / 2,
    this.offset = 12,
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
      collisionType: CollisionType.active,
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

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ElementParticle) {
      if (other.type == type.opposite) {
        other.removeFromParent();
      }
    }
  }
}
