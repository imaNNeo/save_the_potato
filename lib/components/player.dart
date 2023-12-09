import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_fire_game/components/shield.dart';

import '../cubit/game_cubit.dart';
import 'element_ball.dart';
import '../my_game.dart';

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

  int arrowLeftOrRight = 0;

  late Sprite potatoSprite;

  double get radius => size.x / 2;

  void onPanStart(DragStartInfo info) => _initPan(info.eventPosition.global);

  void onPanDown(DragDownInfo info) => _initPan(info.eventPosition.global);

  void _initPan(Vector2 touchGlobalPos) {
    final dir = game.camera.globalToLocal(touchGlobalPos) - position;
    panStartAngle = atan2(dir.x, dir.y);
  }

  void onPanUpdate(DragUpdateInfo info) {
    final dir = game.camera.globalToLocal(info.eventPosition.global) - position;
    final angle = atan2(dir.x, dir.y);
    fireShield.angle += (panStartAngle! - angle);
    _initPan(info.eventPosition.global);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    potatoSprite = await Sprite.load('potato.png');
    add(CircleHitbox(
      collisionType: CollisionType.active,
      radius: radius * 0.7,
      position: size / 2,
      anchor: Anchor.center,
    ));
    add(fireShield = Shield(type: TemperatureType.hot));
    add(iceShield = Shield(type: TemperatureType.cold));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (arrowLeftOrRight != 0) {
      final angle = arrowLeftOrRight * dt * 2 * pi;
      fireShield.angle += angle;
    }
    iceShield.angle = fireShield.angle - pi;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    potatoSprite.render(
      canvas,
      size: size,
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is ElementBall) {
      game.onElementBallHit(other.type);
      other.removeFromParent();
    }
  }

  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isLeftArrow = keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightArrow = keysPressed.contains(LogicalKeyboardKey.arrowRight);

    arrowLeftOrRight = 0;

    if (isLeftArrow && isRightArrow && event is RawKeyDownEvent) {
      return KeyEventResult.handled;
    }

    if (isLeftArrow) {
      arrowLeftOrRight += -1;
      arrowLeftOrRight = arrowLeftOrRight.clamp(-1, 1);
    }

    if (isRightArrow) {
      arrowLeftOrRight += 1;
      arrowLeftOrRight = arrowLeftOrRight.clamp(-1, 1);
    }

    if (arrowLeftOrRight != 0) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
