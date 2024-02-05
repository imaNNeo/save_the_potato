import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:save_the_potato/presentation/components/guide_title.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import '../my_game.dart';
import 'moving/moving_components.dart';
import 'moving/orb/orb_type.dart';

class Potato extends PositionComponent
    with
        HasGameRef<MyGame>,
        CollisionCallbacks,
        FlameBlocListenable<GameCubit, GameState> {
  Potato({
    double size = 100,
  }) : super(
          size: Vector2.all(size),
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  late final Shield fireShield;
  late final Shield iceShield;

  double get radius => size.x / 2;

  late SMITrigger fireHitTrigger;
  late SMITrigger iceHitTrigger;

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  Future<void> onLoad() async {
    super.onLoad();
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
    potatoArtBoard.addController(controller);
    add(RiveComponent(
      artboard: potatoArtBoard,
      size: Vector2.all(152),
      anchor: Anchor.center,
      position: size / 2,
    ));
    add(fireShield = Shield(type: OrbType.fire));
    add(iceShield = Shield(type: OrbType.ice));

    if (game.playingState.isGuide) {
      add(GuideTitle());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (bloc.state.playingState.isPlaying) {
      final rotationSpeed = bloc.state.shieldsAngleRotationSpeed;
      if (rotationSpeed != 0) {
        fireShield.angle += rotationSpeed * dt;
      }
    }
    iceShield.angle = fireShield.angle - pi;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is MovingComponent) {
      switch (other) {
        case MovingHealth():
          game.onHealthPointReceived();
        case FireOrb():
          game.onOrbHit();
          fireHitTrigger.fire();
        case IceOrb():
          game.onOrbHit();
          iceHitTrigger.fire();
      }
      other.removeFromParent();
    }
  }
}
