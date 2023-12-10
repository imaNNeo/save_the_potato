import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:save_the_potato/components/shield.dart';
import 'package:save_the_potato/components/two-way-arrow.dart';

import '../cubit/game_cubit.dart';
import '../my_game.dart';
import 'orb.dart';

class Player extends PositionComponent
    with
        HasGameRef<MyGame>,
        CollisionCallbacks,
        FlameBlocListenable<GameCubit, GameState> {
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

  late SMITrigger fireHitTrigger;
  late SMITrigger iceHitTrigger;
  late SMITrigger fireDieTrigger;
  late SMITrigger iceDieTrigger;

  void onPanStart(DragStartInfo info) => _initPan(info.eventPosition.global);

  void onPanDown(DragDownInfo info) => _initPan(info.eventPosition.global);

  void _initPan(Vector2 touchGlobalPos) {
    final dir = game.camera.globalToLocal(touchGlobalPos) - position;
    panStartAngle = atan2(dir.x, dir.y);
    bloc.guideInteracted();
  }

  void onPanUpdate(DragUpdateInfo info) {
    if (!bloc.state.playingState.isPlaying) {
      return;
    }
    final dir = game.camera.globalToLocal(info.eventPosition.global) - position;
    final angle = atan2(dir.x, dir.y);
    fireShield.angle += (panStartAngle! - angle);
    _initPan(info.eventPosition.global);
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    if (state.playingState.isGameOver) {
      if (state.heatLevel > 0) {
        fireDieTrigger.fire();
      } else {
        iceDieTrigger.fire();
      }
    }
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

    final potatoArtBoard = await loadArtboard(
      RiveFile.asset('assets/rive/potato.riv'),
    );

    final controller = StateMachineController.fromArtboard(
      potatoArtBoard,
      "State Machine 1",
    )!;
    fireHitTrigger = controller.findInput<bool>('fire-hit') as SMITrigger;
    iceHitTrigger = controller.findInput<bool>('ice-hit') as SMITrigger;
    fireDieTrigger = controller.findInput<bool>('fire-die') as SMITrigger;
    iceDieTrigger = controller.findInput<bool>('ice-die') as SMITrigger;
    potatoArtBoard.addController(controller);
    add(CustomRiveComponent(
      artboard: potatoArtBoard,
      size: Vector2.all(152),
      anchor: Anchor.center,
      position: size / 2,
    ));
    add(fireShield = Shield(type: TemperatureType.hot));
    add(iceShield = Shield(type: TemperatureType.cold));

    if (game.playingState.isGuide) {
      add(TwoWayArrow());
    }
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Orb) {
      game.onElementBallHit(other.type);
      if (bloc.state.playingState.isPlaying) {
        switch (other.type) {
          case TemperatureType.hot:
            fireHitTrigger.fire();
            break;
          case TemperatureType.cold:
            iceHitTrigger.fire();
            break;
        }
      }
      other.removeFromParent();
    }
  }

  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isLeftArrow = keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightArrow = keysPressed.contains(LogicalKeyboardKey.arrowRight);

    arrowLeftOrRight = 0;

    if (isLeftArrow || isRightArrow) {
      bloc.guideInteracted();
    }

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
      if (!bloc.state.playingState.isPlaying) {
        arrowLeftOrRight = 0;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class CustomRiveComponent extends RiveComponent {
  CustomRiveComponent({
    required super.artboard,
    super.size,
    super.anchor,
    super.position,
  });

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.clipRect(Rect.fromCircle(
      center: (size / 2).toOffset(),
      radius: size.x / 3,
    ));
    super.render(canvas);
    canvas.restore();
  }
}
