import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/presentation/effects/camera_zoom_effect.dart';
import 'package:save_the_potato/presentation/effects/game_over_effects.dart';

import 'components/moving/moving_components.dart';
import 'components/moving/orb/orb_type.dart';
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
    await FlameAudio.audioCache.load('bg.mp3');
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

  double lastSpawnOrbTimer = 0.0;
  MovingHealth? movingHealth;

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

  @override
  void update(double dt) {
    super.update(dt);
    lastSpawnOrbTimer += dt;
    if (lastSpawnOrbTimer >= bloc.state.spawnOrbsEvery &&
        movingHealth == null) {
      lastSpawnOrbTimer = 0.0;
      spawnOrb();
    }
  }

  int _firstTimeHealthGeneratedCount = 0;

  bool _shouldSpawnHeart() {
    final missingHP = GameConstants.maxHealthPoints - bloc.state.healthPoints;
    if (missingHP == 0) {
      return false;
    }
    late double generateHealthChance;
    if (bloc.state.firstHealthReceived) {
      generateHealthChance = GameConstants.chanceToSpawnHeart;
    } else {
      if (_firstTimeHealthGeneratedCount <
          GameConstants.spawnHeartForFirstTimeMaxCount) {
        generateHealthChance = GameConstants.chanceToSpawnHeartForFirstTime;
      } else {
        generateHealthChance = GameConstants.chanceToSpawnHeart;
      }
      _firstTimeHealthGeneratedCount++;
    }

    return Random().nextDouble() <= generateHealthChance;
  }

  void spawnOrb() {
    if (game.playingState != const PlayingStatePlaying()) {
      return;
    }

    final distance = (game.size.x / 2) + (game.size.x * 0.05);
    final angle = Random().nextDouble() * pi * 2;
    final position = Vector2(cos(angle), sin(angle)) * distance;

    final moveSpeed = bloc.state.spawnOrbsMoveSpeedRange.random();
    final size = 16 + Random().nextDouble() * 2;
    final target = game.world.player;
    final startPosition = position.clone();
    if (_shouldSpawnHeart()) {
      final healthMoveSpeed =
          (moveSpeed * GameConstants.movingHealthPointSpeedMultiplier).clamp(
        GameConstants.movingHealthMinSpeed,
        GameConstants.movingHealthMaxSpeed,
      );
      add(movingHealth = MovingHealth(
        speed: healthMoveSpeed,
        size: size * 1.5,
        target: target,
        position: startPosition,
      ));
      movingHealth!.removed.then((value) {
        movingHealth = null;
      });
    } else {
      switch (OrbType.values.random()) {
        case OrbType.fire:
          add(FireOrb(
            speed: moveSpeed,
            size: size,
            target: target,
            position: startPosition,
          ));
          break;
        case OrbType.ice:
          add(IceOrb(
            speed: moveSpeed,
            size: size,
            target: target,
            position: startPosition,
          ));
          break;
      }
    }
  }
}
