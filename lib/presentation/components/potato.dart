import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/presentation/components/guide_title.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/service_locator.dart';

import '../potato_game.dart';
import 'moving/moving_components.dart';
import 'moving/orb/orb_type.dart';

class Potato extends PositionComponent
    with
        HasGameReference<PotatoGame>,
        CollisionCallbacks,
        FlameBlocListenable<GameCubit, GameState>,
        ParentIsA<MyWorld> {
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

  /*
  * StateMachine guide:
  * Entry -> Idle
  * Idle -> fire-hit
  * Idle -> ice-hit
  * idle -> heart-hit
  * Idle -> Die -> Respawn
  * Idle -> Scared
  * Idle -> Amazed
  * Scared -> ToIdle
  * Scared -> Die
  * */
  late StateMachineController _controller;
  late SMITrigger fireHitTrigger;
  late SMITrigger iceHitTrigger;
  late SMITrigger heartHitTrigger;
  late SMITrigger dieTrigger;
  late SMITrigger scaredTrigger;
  late SMITrigger toIdleTrigger;
  late SMITrigger amazedTrigger;

  final _audioHelper = getIt.get<AudioHelper>();
  GameState? _lastState;

  @override
  void onNewState(GameState state) {
    if (_lastState?.playingState != state.playingState &&
        state.playingState is PlayingStateGameOver) {
      dieTrigger.fire();
    }
    if (_lastState?.currentGameMode.runtimeType !=
        state.currentGameMode.runtimeType) {
      // GameMode is changed
      switch (state.currentGameMode) {
        case GameModeSingleSpawn():
          if (state.gameModeHistory.isEmpty) {
            toIdleTrigger.fire();
            return;
          }
          final previousMode = state.gameModeHistory.last as GameModeMultiSpawn;
          if (!previousMode.shouldPlayMotivationWord()) {
            toIdleTrigger.fire();
          }
        case GameModeMultiSpawn():
          scaredTrigger.fire();
      }
    }
    if (state.playMotivationWord != null) {
      amazedTrigger.fire();
    }
    _lastState = state;
  }

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

    _controller = StateMachineController.fromArtboard(
      potatoArtBoard,
      "State Machine 1",
    )!;
    fireHitTrigger = _controller.findInput<bool>('fire-hit') as SMITrigger;
    iceHitTrigger = _controller.findInput<bool>('ice-hit') as SMITrigger;
    heartHitTrigger = _controller.findInput<bool>('heart-hit') as SMITrigger;
    dieTrigger = _controller.findInput<bool>('Die') as SMITrigger;
    scaredTrigger = _controller.findInput<bool>('Scared') as SMITrigger;
    toIdleTrigger = _controller.findInput<bool>('ToIdle') as SMITrigger;
    amazedTrigger = _controller.findInput<bool>('Amazed') as SMITrigger;
    potatoArtBoard.addController(_controller);
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

    mounted.then((_) {
      _lastState = bloc.state;
    });
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
          getIt.get<AnalyticsHelper>().heartReceived();
          _audioHelper.playHeartHitSound();
          game.onHealthPointReceived();
          heartHitTrigger.fire();
          other.onConsumed();
          break;
        case FireOrb():
          _audioHelper.playOrbHitSound();
          game.onOrbHit();
          if (bloc.state.healthPoints > 0) {
            fireHitTrigger.fire();
          }
          other.onPotatoHit();
          break;
        case IceOrb():
          _audioHelper.playOrbHitSound();
          game.onOrbHit();
          if (bloc.state.healthPoints > 0) {
            iceHitTrigger.fire();
          }
          other.onPotatoHit();
        break;
      }
      other.removeFromParent();
    }
  }

  @override
  void onRemove() {
    _controller.dispose();
    super.onRemove();
  }
}
