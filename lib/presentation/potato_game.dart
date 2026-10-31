import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:save_the_potato/presentation/background_reactions.dart';
import 'package:save_the_potato/presentation/cubit/settings/settings_cubit.dart';
import 'package:save_the_potato/presentation/effects/camera_zoom_effect.dart';
import 'package:save_the_potato/presentation/effects/game_over_effects.dart';
import 'package:save_the_potato/presentation/prototypes/autopilot.dart';
import 'package:save_the_potato/presentation/prototypes/boss.dart';
import 'package:save_the_potato/presentation/prototypes/prototypes.dart';

import 'components/motivation_component.dart';
import 'components/moving/moving_component_spawner.dart';
import 'components/potato.dart';
import 'components/orb_effects.dart';
import 'components/shield_impact_effects.dart';
import 'cubit/game/game_cubit.dart';

class PotatoGame extends FlameGame<MyWorld>
    with HasCollisionDetection, KeyboardEvents {
  PotatoGame(
    this._gameCubit,
    this._settingsCubit, [
    BackgroundReactions? background,
  ]) : background = background ?? BackgroundReactions(),
       super(
         world: MyWorld(),
         camera: CameraComponent.withFixedResolution(width: 600, height: 600),
       );

  /// The stars background is rendered behind the game, see `MainPage`.
  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await Flame.images.loadAll([
      ...List.generate(8, (index) => 'flame/flame${index + 1}.png'),
      ...List.generate(2, (index) => 'snow/snowflake${index + 1}.png'),
      ...List.generate(2, (index) => 'sparkle/sparkle${index + 1}.png'),
      'two-way-arrow.png',
    ]);
    remove(world);
    add(
      FlameMultiBlocProvider(
        providers: [
          FlameBlocProvider<GameCubit, GameState>.value(value: _gameCubit),
          FlameBlocProvider<SettingsCubit, SettingsState>.value(
            value: _settingsCubit,
          ),
        ],
        children: [world],
      ),
    );
  }

  final GameCubit _gameCubit;
  final SettingsCubit _settingsCubit;

  /// Makes the stars background react to the game
  final BackgroundReactions background;

  PlayingState get playingState => _gameCubit.state.playingState;

  GameState get gameCubitState => _gameCubit.state;

  Random rnd = Random();

  @override
  void update(double dt) {
    if (Prototypes.autopilot) {
      Autopilot.drive(this, _gameCubit, dt);
    }
    _gameCubit.update(dt);
    super.update(dt);
  }

  /// An orb coming from [angle] hit the potato
  void onOrbHit(double angle) {
    background.potatoHit(angle);
    _gameCubit.potatoOrbHit();
    camera.viewfinder.add(
      MoveEffect.by(
        Vector2(8, 8),
        NoiseEffectController(duration: 1, noise: PerlinNoise(frequency: 400)),
      ),
    );
  }

  void onHealthPointReceived() {
    background.healed();
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
    with
        HasGameReference<PotatoGame>,
        FlameBlocListenable<GameCubit, GameState> {
  late Potato player;

  late ShieldImpactEffects shieldImpacts;

  late OrbEffects orbEffects;

  late StreamSubscription _motivationWordSubscription;

  @override
  Future<void> onLoad() async {
    await add(shieldImpacts = ShieldImpactEffects());
    await add(orbEffects = OrbEffects());
    await add(player = Potato());
    await add(MovingComponentSpawner());
    if (Prototypes.boss) {
      await add(BossFight());
    }
    mounted.then((_) {
      _motivationWordSubscription = bloc.stream
          .map((state) => state.playMotivationWord)
          .distinct()
          .where((word) => word != null)
          .listen((playMotivationWord) {
            addMotivationWord(playMotivationWord!);
          });
    });
  }

  void addMotivationWord(MotivationWordType type) {
    add(
      MotivationComponent(
        position: player.positionOfAnchor(Anchor.center),
        motivationWordType: type,
        inDuration: lerpDouble(1.25, 0.9, bloc.state.difficulty)!,
        outDuration: lerpDouble(4.0, 2.0, bloc.state.difficulty)!,
      ),
    );
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
      add(
        CameraZoomEffect(
          controller: EffectController(duration: 1.0),
          zoomTo: 1.0,
        ),
      );
    }
  }

  @override
  void onRemove() {
    _motivationWordSubscription.cancel();
    super.onRemove();
  }
}
