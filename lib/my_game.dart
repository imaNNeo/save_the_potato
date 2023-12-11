import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:save_the_potato/effects/camera_zoom_effect.dart';
import 'package:save_the_potato/effects/game_over_effects.dart';

import 'components/orb.dart';
import 'cubit/game_cubit.dart';
import 'components/potato.dart';

class MyGame extends FlameGame<MyWorld>
    with PanDetector, HasCollisionDetection, KeyboardEvents {
  MyGame(this._gameCubit)
      : super(
          world: MyWorld(),
          camera: CameraComponent.withFixedResolution(
            width: 600,
            height: 600,
          ),
        );

  @override
  Future<void> onLoad() async {
    await FlameAudio.audioCache.load('bg.mp3');
    await Flame.images.loadAll([
      ...List.generate(8, (index) => 'flame/flame${index + 1}.png'),
      ...List.generate(2, (index) => 'snow/snowflake${index + 1}.png'),
      ...List.generate(2, (index) => 'sparkle/sparkle${index + 1}.png'),
      'two-way-arrow.png',
    ]);
    remove(world);
    add(FlameBlocProvider<GameCubit, GameState>(
      create: () => _gameCubit,
      children: [world],
    ));
  }

  final GameCubit _gameCubit;

  PlayingState get playingState => _gameCubit.state.playingState;

  Random rnd = Random();

  @override
  void update(double dt) {
    _gameCubit.update(dt);
    super.update(dt);
  }

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
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) =>
      world.player.onKeyEvent(event, keysPressed);
}

class MyWorld extends World
    with HasGameRef<MyGame>, FlameBlocListenable<GameCubit, GameState> {
  late Potato player;

  double lastSpawnOrbTimer = 0.0;

  @override
  Future<void> onLoad() async {
    await add(player = Potato());
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (state.playingState == PlayingState.gameOver) {
      add(GameOverCameraZoomEffect());
    } else {
      add(CameraZoomEffect(
        controller: EffectController(
          duration: 1.0,
        ),
        zoomTo: 1.0,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    lastSpawnOrbTimer += dt;
    if (lastSpawnOrbTimer >= bloc.state.spawnOrbsEvery) {
      lastSpawnOrbTimer = 0.0;
      spawnOrb();
    }
  }

  double _getSpawnRandomDistance() {
    final distanceMin = player.size.x * 2;
    final distanceMax = (game.size.x / 2) - (game.size.x * 0.05);
    final distanceDiff = distanceMax - distanceMin;
    return distanceMin + Random().nextDouble() * distanceDiff;
  }

  void spawnOrb() {
    if (game.playingState != PlayingState.playing) {
      return;
    }

    final distance = _getSpawnRandomDistance();
    final angle = Random().nextDouble() * pi * 2;
    final position = Vector2(cos(angle), sin(angle)) * distance;

    const speedMin = 160;
    const speedMax = 200;
    add(Orb(
      type: TemperatureType.values.random(),
      speed: Random().nextDouble() * (speedMax - speedMin) + speedMin,
      size: 16 + Random().nextDouble() * 2,
      target: game.world.player,
      position: position.clone(),
    ));
  }
}
