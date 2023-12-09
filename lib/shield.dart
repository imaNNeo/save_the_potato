import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'element.dart';
import 'my_game.dart';
import 'player.dart';


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
      if (other.type == type) {
        other.removeFromParent();
      }
    }
  }
}