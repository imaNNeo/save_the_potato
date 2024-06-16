import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/presentation/effects/camera_zoom_effect.dart';
import 'package:save_the_potato/presentation/effects/game_over_effects.dart';

import 'components/moving/moving_component_spawner.dart';
import 'components/potato.dart';
import 'cubit/game/game_cubit.dart';

class MyGame extends FlameGame<MyWorld>
    with HasCollisionDetection, KeyboardEvents {
  MyGame(
    this._gameCubit,
    this._settingsCubit,
  ) : super(
          world: MyWorld(),
          camera: CameraComponent.withFixedResolution(
            width: 600,
            height: 600,
          ),
        );

  @override
  Future<void> onLoad() async {
    await Flame.images.loadAll([
      ...List.generate(8, (index) => 'flame/flame${index + 1}.png'),
      ...List.generate(2, (index) => 'snow/snowflake${index + 1}.png'),
      ...List.generate(2, (index) => 'sparkle/sparkle${index + 1}.png'),
      'two-way-arrow.png',
    ]);
    remove(world);
    add(FlameMultiBlocProvider(
      providers: [
        FlameBlocProvider<GameCubit, GameState>.value(value: _gameCubit),
        FlameBlocProvider<SettingsCubit, SettingsState>.value(
          value: _settingsCubit,
        ),
      ],
      children: [world],
    ));
  }

  final GameCubit _gameCubit;
  final SettingsCubit _settingsCubit;

  PlayingState get playingState => _gameCubit.state.playingState;

  Random rnd = Random();

  @override
  void update(double dt) {
    _gameCubit.update(dt);
    super.update(dt);
  }

  void onOrbHit() {
    _gameCubit.potatoOrbHit();
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

  void onHealthPointReceived() {
    _gameCubit.onPotatoHealthPointReceived();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    return _gameCubit.handleKeyEvent(event, keysPressed);
  }
}

class MyWorld extends World
    with HasGameRef<MyGame>, FlameBlocListenable<GameCubit, GameState> {
  late Potato player;

  @override
  Future<void> onLoad() async {
    await add(player = Potato());
    await add(MovingComponentSpawner());
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (state.playingState is PlayingStateGameOver) {
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
}
