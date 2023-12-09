import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:save_the_potato/effects/camera_zoom_effect.dart';

import 'cubit/game_cubit.dart';
import 'components/element_ball.dart';
import 'components/player.dart';

class MyGame extends FlameGame<MyWorld>
    with PanDetector, HasCollisionDetection, KeyboardEvents {
  MyGame(this._gameCubit)
      : super(
          world: MyWorld(),
          camera: CameraComponent.withFixedResolution(
            width: 800,
            height: 800,
          ),
        );

  @override
  void onLoad() {
    remove(world);
    add(FlameBlocProvider<GameCubit, GameState>(
      create: () => _gameCubit,
      children: [world],
    ));
  }

  final GameCubit _gameCubit;

  PlayingState get playingState => _gameCubit.state.playingState;

  Random rnd = Random();

  final hotColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
  ];

  final coldColors = [
    Colors.white,
    Colors.lightBlueAccent,
    Colors.blue,
  ];

  @override
  void onPanStart(DragStartInfo info) => world.player.onPanStart(info);

  @override
  void onPanDown(DragDownInfo info) => world.player.onPanDown(info);

  @override
  void onPanUpdate(DragUpdateInfo info) => world.player.onPanUpdate(info);

  void onElementBallHit(TemperatureType type) {
    _gameCubit.potatoElementBallHit(type);
    camera.viewfinder.add(
      MoveEffect.by(
        Vector2(8, 8),
        PerlinNoiseEffectController(
          duration: 1,
          frequency: 400,
        ),
      ),
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF251E2C);

  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) =>
      world.player.onKeyEvent(event, keysPressed);
}

class MyWorld extends World
    with
        HasGameRef<MyGame>,
        FlameBlocListenable<GameCubit, GameState> {
  late Player player;

  @override
  Future<void> onLoad() async {
    await add(player = Player());
    add(TimerComponent(
      period: 1.5,
      repeat: true,
      onTick: _spawnSpawner,
    ));
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (state.playingState == PlayingState.gameOver) {
      add(CameraZoomEffect(
        controller: EffectController(
          duration: 1.0,
          curve: Curves.easeOut,
        ),
        zoomTo: 2.0,
      ));
    } else {
      add(CameraZoomEffect(
        controller: EffectController(
          duration: 1.0,
        ),
        zoomTo: 1.0,
      ));
    }
  }

  double _getSpawnRandomDistance() {
    final distanceMin = player.size.x * 3;
    final distanceMax = game.size.x / 2;
    final distanceDiff = distanceMax - distanceMin;
    return distanceMin + Random().nextDouble() * distanceDiff;
  }

  void _spawnSpawner() {
    final distance = _getSpawnRandomDistance();
    final angle = Random().nextDouble() * pi * 2;
    final position = Vector2(cos(angle), sin(angle)) * distance;

    final spawner = ElementBallSpawner(
      position: position,
      type: TemperatureType.values[Random().nextInt(2)],
      spawnInterval: 0.0,
      spawnCount: 1,
    );
    add(spawner);
  }
}
