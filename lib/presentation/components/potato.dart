import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/presentation/components/guide_title.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/service_locator.dart';

import '../my_game.dart';
import 'moving/moving_components.dart';
import 'moving/orb/color_type.dart';

class Potato extends PositionComponent
    with
        HasGameRef<MyGame>,
        CollisionCallbacks,
        ParentIsA<MyWorld>,
        FlameBlocListenable<GameCubit, GameState> {
  Potato({
    double size = 100,
  }) : super(
          size: Vector2.all(size),
          position: Vector2.all(0),
          anchor: Anchor.center,
        );

  final List<Shield> shields = [];

  double get radius => size.x / 2;

  late StateMachineController _controller;
  late SMITrigger fireHitTrigger;
  late SMITrigger iceHitTrigger;
  late SMITrigger heartHitTrigger;
  late SMITrigger dieTrigger;
  late StreamSubscription _shieldsSubscription;

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    if (state.playingState is PlayingStateGameOver) {
      dieTrigger.fire();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await add(CircleHitbox(
      collisionType: CollisionType.active,
      radius: radius * 0.7,
      position: size / 2,
      anchor: Anchor.center,
    ));

    final potatoArtBoard = await loadArtboard(
      RiveFile.asset('assets/rive/potato.riv'),
    );

    _controller = StateMachineController.fromArtboard(
      potatoArtBoard,
      "State Machine 1",
    )!;
    fireHitTrigger = _controller.findInput<bool>('fire-hit') as SMITrigger;
    iceHitTrigger = _controller.findInput<bool>('ice-hit') as SMITrigger;
    heartHitTrigger = _controller.findInput<bool>('heart-hit') as SMITrigger;
    dieTrigger = _controller.findInput<bool>('Die') as SMITrigger;
    potatoArtBoard.addController(_controller);
    await add(RiveComponent(
      artboard: potatoArtBoard,
      size: Vector2.all(152),
      anchor: Anchor.center,
      position: size / 2,
    ));
    if (game.playingState.isGuide) {
      add(GuideTitle());
    }

    mounted.then((value) {
      _shieldsSubscription = bloc.stream
          .map((state) => state.activeColorTypes)
          .distinct()
          .listen(_reAddShields);
      _reAddShields(bloc.state.activeColorTypes);
    });
  }

  void _reAddShields(List<ColorType> shieldTypes) {
    for (var shield in shields) {
      shield.removeFromParent();
    }
    shields.clear();
    for (var type in shieldTypes) {
      final shield = Shield(
        shieldSweep: pi / 2,
        type: type,
      );
      shields.add(shield);
      add(shield);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (shields.isNotEmpty) {
      _updateShields(dt);
      return;
    }
  }

  void _updateShields(double dt) {
    if (bloc.state.playingState.isPlaying) {
      final rotationSpeed = bloc.state.shieldsAngleRotationSpeed;
      if (rotationSpeed != 0) {
        shields[0].angle += rotationSpeed * dt;
      }
    }

    for (var shield in shields) {
      shield.shieldSweep = pi / shields.length;
    }

    final totalSweep =
    shields.fold(0.0, (prev, shield) => prev + shield.shieldSweep);
    final totalSpace = (pi * 2) - totalSweep;
    final shieldsSpace = totalSpace / shields.length;
    Shield previousShield = shields[0];
    for (int i = 1; i < shields.length; i++) {
      final currentShield = shields[i];
      shields[i].angle =
          previousShield.angle - (previousShield.shieldSweep + shieldsSpace);
      previousShield = currentShield;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is MovingComponent) {
      switch (other) {
        case MovingHealth():
          getIt.get<AnalyticsHelper>().heartReceived();
          game.onHealthPointReceived();
          heartHitTrigger.fire();
        case MovingOrb():
          game.onOrbHit();
          if (bloc.state.healthPoints > 0) {
            iceHitTrigger.fire();
          }
      }
      other.removeFromParent();
    }
  }

  @override
  void onRemove() {
    _controller.dispose();
    _shieldsSubscription.cancel();
    super.onRemove();
  }
}
