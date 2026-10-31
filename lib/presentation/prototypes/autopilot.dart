import 'dart:math';

import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/potato_game.dart';

import 'prototypes.dart';

/// Plays the game for the prototype videos (`&bot=1`). It turns the right
/// shield towards the orb that is closest to the potato. `&lapse=0.1` makes
/// it ignore about one orb in ten, so a run can end.
class Autopilot {
  static final double _lapse = Prototypes.number('lapse') ?? 0.0;

  /// It only reacts to orbs this close, like a player who waits to see them
  static const _sightRadius = 300.0;

  static double _guideWait = 0;

  /// Menus are driven by the prototype panels, this only starts the round
  static bool holdOnGuide = false;

  static void drive(PotatoGame game, GameCubit cubit, double dt) {
    final playing = cubit.state.playingState;
    if (playing.isGuide) {
      _guideWait += dt;
      if (_guideWait > 1.6 && !holdOnGuide) {
        _guideWait = 0;
        cubit.startFromGuide();
      }
      return;
    }
    if (!playing.isPlaying) {
      return;
    }
    final potato = game.world.player;
    final orbs = game.world.children
        .whereType<MovingOrb>()
        .where((o) => o.isFlying && !_ignores(o))
        .toList();
    if (Prototypes.coop) {
      cubit.steer(_steerOne(potato.fireShield, orbs, OrbType.fire));
      ProtoHooks.iceShieldSpeed =
          _steerOne(potato.iceShield, orbs, OrbType.ice) * pi * 1.8;
      return;
    }
    MovingOrb? target;
    var closest = _sightRadius;
    for (final orb in orbs) {
      final d = orb.position.length;
      if (d < closest) {
        closest = d;
        target = orb;
      }
    }
    if (target == null) {
      cubit.steer(0);
      return;
    }
    var desired = atan2(target.position.y, target.position.x);
    if (target.type == OrbType.ice) {
      desired += pi;
    }
    cubit.steer(_towards(potato.fireShield.angle, desired));
  }

  static double _steerOne(Shield shield, List<MovingOrb> orbs, OrbType type) {
    MovingOrb? target;
    var closest = _sightRadius;
    for (final orb in orbs) {
      final d = orb.position.length;
      if (orb.type == type && d < closest) {
        closest = d;
        target = orb;
      }
    }
    if (target == null) {
      return 0;
    }
    final desired = atan2(target.position.y, target.position.x);
    return _towards(shield.angle, desired);
  }

  static double _towards(double current, double desired) {
    var diff = (desired - current) % (2 * pi);
    if (diff > pi) {
      diff -= 2 * pi;
    }
    return (diff * 6).clamp(-1.0, 1.0);
  }

  static bool _ignores(MovingOrb orb) {
    if (_lapse <= 0) {
      return false;
    }
    final f = (orb.seed * 7.31) % 1.0;
    return f < _lapse;
  }
}
