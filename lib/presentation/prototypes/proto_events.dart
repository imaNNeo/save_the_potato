import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';

import 'levels.dart';
import 'missions.dart';
import 'perks.dart';
import 'prototypes.dart';
import 'themes.dart';

/// What the game tells the prototypes. Each call does nothing unless the
/// matching prototype is on.
class ProtoEvents {
  static int _streak = 0;
  static double _lastLevelTime = 0;

  /// Listeners for orbs blocked by a shield (the boss counts its own)
  static final blockListeners = <void Function(MovingComponent)>[];

  static void runStarted(GameCubit cubit) {
    _streak = 0;
    _lastLevelTime = 0;
    ProtoHooks.iceShieldSpeed = 0;
    ProtoHooks.pauseNormalSpawns = false;
    ProtoHooks.frozen = false;
    switch (Prototypes.active) {
      case Prototype.perks:
        PerkRun.instance.reset();
      case Prototype.levels:
        cubit.setDifficultyTime(Levels.instance.level.startDifficultyTime);
      case Prototype.missions:
        Missions.instance.startRun();
      default:
        break;
    }
  }

  static void tick(GameCubit cubit) {
    final time = cubit.state.levelTimePassed;
    final last = _lastLevelTime;
    _lastLevelTime = time;
    switch (Prototypes.active) {
      case Prototype.perks:
        final run = PerkRun.instance;
        if (run.shouldOpenDraft(time)) {
          run.openDraft();
          freeze(cubit);
        }
      case Prototype.levels:
        final levels = Levels.instance;
        for (final (at, count) in levels.level.waves) {
          if (last < at && time >= at) {
            cubit.startWave(count);
          }
        }
        if (time >= levels.level.seconds && levels.result == null) {
          levels.finish(cubit.state.healthPoints);
          freeze(cubit);
        }
      case Prototype.missions:
        if (time.floor() != last.floor()) {
          Missions.instance.best(MissionKind.survive, time.floor());
        }
      default:
        break;
    }
  }

  static void blocked(GameCubit cubit, MovingComponent component) {
    if (component is! MovingOrb) {
      return;
    }
    _streak++;
    for (final listener in [...blockListeners]) {
      listener(component);
    }
    switch (Prototypes.active) {
      case Prototype.perks:
        final every = PerkRun.instance.streakHealEvery;
        if (every != null && _streak % every == 0) {
          cubit.onPotatoHealthPointReceived();
        }
      case Prototype.missions:
        final missions = Missions.instance;
        missions.add(switch (component.type) {
          OrbType.fire => MissionKind.blockFire,
          OrbType.ice => MissionKind.blockIce,
        });
        missions.best(MissionKind.streak, _streak);
      default:
        break;
    }
  }

  static void potatoHit() {
    _streak = 0;
  }

  static void heartReceived() {
    if (Prototypes.missions) {
      Missions.instance.add(MissionKind.hearts);
    }
  }

  static void waveFinished(GameModeMultiSpawn wave) {
    if (Prototypes.missions && wave.collidedOrbsCount == 0) {
      Missions.instance.add(MissionKind.flawlessWave);
    }
  }

  static void gameOver(double levelTime) {
    if (Prototypes.themes) {
      ShieldThemes.sparks += levelTime.floor();
    }
  }

  /// Stops the game under a prototype panel (perk draft, level result)
  static void freeze(GameCubit cubit) {
    ProtoHooks.frozen = true;
    cubit.pauseGame(manually: false);
  }

  static void unfreeze(GameCubit cubit) {
    ProtoHooks.frozen = false;
    cubit.resumeGame();
  }

  /// Co-op: A and D turn the fire shield, the arrows turn the ice shield
  static KeyEventResult? handleCoopKeys(
    GameCubit cubit,
    Set<LogicalKeyboardKey> keys,
    double maxSpeed,
  ) {
    if (!Prototypes.coop) {
      return null;
    }
    double dir(LogicalKeyboardKey left, LogicalKeyboardKey right) =>
        (keys.contains(left) ? -1.0 : 0.0) + (keys.contains(right) ? 1.0 : 0.0);
    final fire = dir(LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyD);
    final ice = dir(
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    );
    if (fire != 0 || ice != 0) {
      cubit.startFromGuide();
    }
    cubit.steer(fire);
    ProtoHooks.iceShieldSpeed = ice * maxSpeed;
    return KeyEventResult.handled;
  }
}
