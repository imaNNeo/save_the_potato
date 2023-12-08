import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MyWorld extends World {
  @override
  Future<void> onLoad() async {
    await add(Player());
  }
}

class Player extends PositionComponent {
  Player({
    double size = 100,
  }) : super(
          size: Vector2.all(size),
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  late final Shield fireShield;
  late final Shield iceShield;

  @override
  void onLoad() {
    super.onLoad();
    add(fireShield = Shield(color: Colors.red));
    add(iceShield = Shield(color: Colors.blue));
  }

  @override
  void update(double dt) {
    super.update(dt);
    iceShield.angle = fireShield.angle - pi / 2;
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

class Shield extends PositionComponent with ParentIsA<Player> {
  Shield({
    required this.color,
    this.shieldWidth = 8.0,
    this.shieldSweep = pi / 2,
    this.offset = 8,
  }) : super(
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  final Color color;
  final double shieldWidth;
  final double shieldSweep;
  final double offset;

  @override
  void update(double dt) {
    size = parent.size + Vector2.all(shieldWidth * 2) + Vector2.all(offset * 2);
    position = parent.size / 2;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawArc(
      size.toRect().deflate(shieldWidth / 2),
      angle - shieldSweep / 2,
      shieldSweep,
      false,
      Paint()
        ..color = color
        ..strokeWidth = shieldWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
}
