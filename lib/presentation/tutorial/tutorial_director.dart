import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:save_the_potato/presentation/components/moving/moving_component_spawner.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

import 'tutorial_style.dart';
import 'tutorial_visuals.dart';

/// The first-time playground: throws one orb at a time, shows the player
/// where the shield should go, and gives feedback on every block and hit.
/// After [blocksToFinish] blocks the real run starts right away.
class TutorialDirector extends Component
    with
        HasGameReference<PotatoGame>,
        ParentIsA<MyWorld>,
        FlameBlocListenable<GameCubit, GameState> {
  TutorialDirector({required this.spawner});

  final MovingComponentSpawner spawner;

  final _audio = getIt.get<AudioHelper>();

  static const blocksToFinish = 6;

  /// Fire first, then ice once fire is understood
  static const _types = [
    OrbType.fire,
    OrbType.fire,
    OrbType.ice,
    OrbType.fire,
    OrbType.ice,
    OrbType.ice,
  ];

  /// Notes of the progress dots, rising to the top A
  static const _notes = [69, 72, 74, 76, 79, 81];

  /// Slower than the real game's first orbs (135)
  static const _guidedSpeed = 95.0;
  static const _soloSpeed = 120.0;

  /// Orb hitbox radius plus the shield's outer radius
  static const _contactDistance = 8.5 + 68.0;

  /// How long a rift forms before its orb comes through
  static const _riftTime = 0.7;

  /// How far inside the shield's edge an orb must be to count as covered
  static const _coverMargin = 10 * pi / 180;

  late final TutorialProgressDots dots;
  late final GhostShield ghost;

  TutorialStyle _style = TutorialStyle.defaultStyle;
  bool _active = false;
  bool _finishing = false;
  int _blocks = 0;
  int _throws = 0;
  bool _lastWasHit = false;

  _Throw? _current;
  double _wait = 0;

  /// The slow-motion style's time scale for the orb
  double _orbTime = 1;

  final _rnd = Random();

  @override
  Future<void> onLoad() async {
    await parent.add(dots = TutorialProgressDots(count: blocksToFinish));
    await parent.add(ghost = GhostShield());
  }

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.tutorial != newState.tutorial;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (state.tutorial && !_active) {
      _begin();
    } else if (!state.tutorial && _active) {
      _active = false;
      ghost.hide();
      bloc.setTutorialHint(0);
    }
  }

  void _begin() {
    _active = true;
    _finishing = false;
    _style = bloc.tutorialStyle ?? TutorialStyle.defaultStyle;
    _blocks = 0;
    _throws = 0;
    _lastWasHit = false;
    _current = null;
    _wait = 0.6;
    dots.show();
  }

  double get _fireAngle => parent.player.fireShield.angle;

  /// The fire shield's angle that puts the right shield in front of [t]
  double _needFor(_Throw t) => t.type == OrbType.fire ? t.angle : t.angle + pi;

  static double _wrap(double a) {
    var x = (a + pi) % (2 * pi);
    if (x < 0) {
      x += 2 * pi;
    }
    return x - pi;
  }

  double _offBy(_Throw t) => _wrap(_needFor(t) - _fireAngle);

  bool _covered(_Throw t) =>
      _offBy(t).abs() < Shield.defaultSweep / 2 - _coverMargin;

  /// Is help on for this orb? Each style answers differently
  bool _guidedFromStart() => switch (_style) {
    TutorialStyle.ghost => _blocks < 3 || _lastWasHit,
    TutorialStyle.slowMo => false,
    TutorialStyle.ouch => false,
  };

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active || !bloc.state.playingState.isPlaying) {
      return;
    }
    if (_wait > 0) {
      _wait -= dt;
      if (_wait <= 0) {
        _afterWait();
      }
    }
    final t = _current;
    if (t != null) {
      _tick(t, dt);
    }
    if (TutorialStyle.bot) {
      _bot.update(this, dt);
    }
  }

  void Function()? _then;

  void _afterWait() {
    final then = _then;
    _then = null;
    if (then != null) {
      then();
    } else if (_current == null && !_finishing) {
      _throwNext();
    }
  }

  void _throwNext({_Throw? repeat}) {
    final type = repeat?.type ?? _types[_blocks % _types.length];
    late double angle;
    if (repeat != null) {
      angle = repeat.angle;
    } else {
      // Far enough from where the shield is, so the player has to turn
      final turn = (80 + _rnd.nextDouble() * 60) * pi / 180;
      final need = _fireAngle + (_rnd.nextBool() ? turn : -turn);
      angle = type == OrbType.fire ? need : need - pi;
    }
    final t = _Throw(type: type, angle: _wrap(angle), index: _throws++);
    t.guided = _guidedFromStart() || (repeat?.guided ?? false);
    _current = t;
    t.rift = RingRift(type: type, spawnAngle: t.angle, formDuration: _riftTime);
    parent.add(t.rift!);
    if (t.guided) {
      ghost.showFor(type, _needFor(t), angleOfOrb: t.angle);
    }
    if (t.holdUntilCovered) {
      return;
    }
    t.launchIn = _riftTime;
  }

  void _launch(_Throw t) {
    t.launched = true;
    final speed = t.guided || _style == TutorialStyle.slowMo
        ? _guidedSpeed
        : _soloSpeed;
    t.orb = spawner.spawnRhythmOrb(
      type: t.type,
      position: Vector2(cos(t.angle), sin(t.angle)) * (ArenaRing.radius + 10),
      speed: speed,
      onBlocked: () => _onBlocked(t),
      onHit: () => _onHit(t),
    );
    t.closeRiftIn = 0.45;
  }

  void _tick(_Throw t, double dt) {
    if (t.launchIn != null) {
      t.launchIn = t.launchIn! - dt;
      if (t.launchIn! <= 0) {
        t.launchIn = null;
        _launch(t);
      }
    }
    if (t.closeRiftIn != null) {
      t.closeRiftIn = t.closeRiftIn! - dt;
      if (t.closeRiftIn! <= 0) {
        t.closeRiftIn = null;
        t.rift?.close();
      }
    }

    // The ouch style waits, rift open, until the shield is where it was
    // shown after the hit
    if (t.holdUntilCovered && !t.launched && t.launchIn == null) {
      if (_covered(t)) {
        t.launchIn = 0.35;
      }
    }

    if (_style == TutorialStyle.slowMo) {
      _slowMo(t, dt);
    }

    ghost.from = t.type == OrbType.fire ? _fireAngle : _fireAngle - pi;
    final showHelp = ghost.isShowing && !t.done;
    final covered = _covered(t);
    ghost.locked = covered;
    if (showHelp && !covered) {
      bloc.setTutorialHint(_offBy(t) > 0 ? 1 : -1);
    } else {
      bloc.setTutorialHint(0);
    }
  }

  void _slowMo(_Throw t, double dt) {
    final orb = t.orb;
    var target = 1.0;
    if (orb != null && t.launched && !t.done) {
      final distance = orb.position.length - _contactDistance;
      // Strong help for the first blocks, and after a miss
      final strong = _blocks < 3 || _lastWasHit;
      final reach = strong ? 120.0 : 70.0;
      if (!_covered(t) && distance < reach && strong) {
        target = 0.05;
        if (!ghost.isShowing) {
          ghost.showFor(t.type, _needFor(t), angleOfOrb: t.angle);
          parent.player.face.scared();
        }
      }
    }
    // Into slow motion fast, out of it a bit slower so it reads
    final rate = target < _orbTime ? 14.0 : 5.0;
    _orbTime += (target - _orbTime) * min(1, dt * rate);
    orb?.timeScale = _orbTime;
    ghost.slowMo = 1 - _orbTime;
  }

  void _onBlocked(_Throw t) {
    if (t.done || !_active) {
      return;
    }
    t.done = true;
    _current = null;
    _orbTime = 1;
    ghost.slowMo = 0;
    bloc.setTutorialHint(0);
    final note = _notes[_blocks.clamp(0, _notes.length - 1)];
    _blocks++;
    _lastWasHit = false;
    ghost.success();
    dots.fill(_blocks, t.type);
    _audio.playNote(t.type == OrbType.fire ? 'fire' : 'ice', note + 12);
    parent.player.face.amazed();
    if (_blocks >= blocksToFinish) {
      _finish();
      return;
    }
    _wait = 0.55;
  }

  void _onHit(_Throw t) {
    if (t.done || !_active) {
      return;
    }
    t.done = true;
    _current = null;
    _orbTime = 1;
    ghost.slowMo = 0;
    bloc.setTutorialHint(0);
    _lastWasHit = true;
    dots.miss();
    // Show where the shield should have been
    ghost.showMiss(t.type, _needFor(t), angleOfOrb: t.angle);
    switch (_style) {
      case TutorialStyle.ghost || TutorialStyle.slowMo:
        // The same orb again, with help this time
        _wait = 1.1;
        _then = () {
          final again = _Throw(type: t.type, angle: t.angle, index: 0)
            ..guided = _style == TutorialStyle.ghost;
          _throwNext(repeat: again);
        };
      case TutorialStyle.ouch:
        // Freeze on the mistake, then wait for the shield to go there
        _wait = 0.9;
        _then = () {
          final again = _Throw(type: t.type, angle: t.angle, index: 0)
            ..guided = true
            ..holdUntilCovered = true;
          _throwNext(repeat: again);
        };
    }
  }

  void _finish() {
    _finishing = true;
    bloc.setTutorialHint(0);
    ghost.hide();
    dots.celebrate();
    _audio.playNote('ice', 81 + 12, volume: 0.9);
    _audio.playNote('fire', 76 + 12, volume: 0.7);
    _wait = 1.0;
    _then = () {
      _active = false;
      dots.hide();
      bloc.finishTutorial();
    };
  }

  // ------------------------------------------------------------------
  // Bot, for videos (`?tutorialbot=1`)

  final _bot = _TutorialBot();
}

class _Throw {
  _Throw({required this.type, required this.angle, required this.index});

  final OrbType type;
  final double angle;
  final int index;

  bool guided = false;
  bool holdUntilCovered = false;
  bool launched = false;
  bool done = false;
  double? launchIn;
  double? closeRiftIn;
  RingRift? rift;
  MovingOrb? orb;
}

/// Plays like a new player: misses on purpose a couple of times, otherwise
/// turns the shield after a short reaction time
class _TutorialBot {
  _Throw? _seen;
  double _react = 0;
  int _held = 0;
  bool _sawGhost = false;

  /// Throws the bot lets through, to show what a miss looks like
  static Set<int> _missThrows(TutorialStyle style) => switch (style) {
    TutorialStyle.ghost => {4},
    TutorialStyle.ouch => {0, 4},
    // It waits for the slow motion instead, which stops coming after a few
    // blocks, so it misses there
    TutorialStyle.slowMo => {},
  };

  void update(TutorialDirector d, double dt) {
    final t = d._current;
    if (t == null || t.done) {
      _press(d, 0);
      return;
    }
    if (_seen != t) {
      _seen = t;
      _react = t.holdUntilCovered ? 0.6 : 1.0;
    }
    if (_missThrows(d._style).contains(t.index)) {
      _press(d, 0);
      return;
    }
    if (d._style == TutorialStyle.slowMo && !t.guided) {
      // Waits for time to slow down, like someone who doesn't know yet
      if (!d.ghost.isShowing) {
        _sawGhost = false;
        _press(d, 0);
        return;
      }
      if (!_sawGhost) {
        _sawGhost = true;
        _react = 0.7;
      }
    }
    if (_react > 0) {
      _react -= dt;
      _press(d, 0);
      return;
    }
    final off = d._offBy(t);
    if (off.abs() < 6 * pi / 180) {
      _press(d, 0);
    } else {
      _press(d, off > 0 ? 1 : -1);
    }
  }

  void _press(TutorialDirector d, int direction) {
    if (_held == direction) {
      return;
    }
    final cubit = d.bloc;
    if (_held == -1) {
      cubit.onLeftTapUp();
    } else if (_held == 1) {
      cubit.onRightTapUp();
    }
    if (direction == -1) {
      cubit.onLeftTapDown();
    } else if (direction == 1) {
      cubit.onRightTapDown();
    }
    _held = direction;
  }
}
