import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/animation.dart';
import 'package:save_the_potato/presentation/components/moving/moving_component_spawner.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/components/shield.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

import 'orb_focus.dart';
import 'tutorial_flags.dart';
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

  /// How long a rift forms before its orb comes through
  static const _riftTime = 0.7;

  /// Where an orb stops and waits when the shield isn't in front of it,
  /// just outside the progress dots
  static const _holdDistance = 160.0;

  /// After waiting this long, the ghost shield comes to help
  static const _ghostAfter = 1.2;

  /// How far inside the shield's edge an orb must be to count as covered
  static const _coverMargin = 10 * pi / 180;

  late final TutorialProgressDots dots;
  late final GhostShield ghost;

  /// Dims the arena around the coming orb, its lane and the potato
  final focus = OrbFocus();

  bool _active = false;
  bool _finishing = false;
  int _blocks = 0;
  int _throws = 0;
  bool _lastWasHit = false;

  _Throw? _current;

  /// The orb that just hit, until it is thrown again
  _Throw? _missed;
  double _wait = 0;

  final _rnd = Random();

  @override
  Future<void> onLoad() async {
    await parent.add(dots = TutorialProgressDots(count: blocksToFinish));
    await parent.add(ghost = GhostShield());
    await parent.add(OrbSpotlight(focus));
    await parent.add(OrbFocusMarks(focus));
    // A soft high note when the shield reaches the right spot
    ghost.onLocked = () => _audio.playNote('ice', 88, volume: 0.45);
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
      focus.clear();
      bloc.setTutorialHint(0);
    }
  }

  void _begin() {
    _active = true;
    _finishing = false;
    _blocks = 0;
    _throws = 0;
    _lastWasHit = false;
    _current = null;
    _missed = null;
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

  /// The ghost shield helps with the first orbs and after a miss
  bool _guidedFromStart() => _blocks < 3 || _lastWasHit;

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active || !bloc.state.playingState.isPlaying) {
      return;
    }
    _playArpeggio(dt);
    if (_wait > 0) {
      _wait -= dt;
      if (_wait <= 0) {
        _afterWait();
      }
    }
    final t = _current;
    if (t != null) {
      _tick(t, dt);
    } else if (_missed != null) {
      // Between a hit and the same orb again, the help stays up and keeps
      // following the shield
      _guide(_missed!, active: true);
    }
    if (TutorialFlags.bot) {
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
    // Every orb comes from the direction of an empty dot, and blocking it
    // fills that dot
    final dot = repeat?.dot ?? _pickDot(type);
    final angle = TutorialProgressDots.angleOf(dot, blocksToFinish);
    final t = _Throw(
      type: type,
      angle: _wrap(angle),
      index: _throws++,
      dot: dot,
    );
    dots.point(dot, type);
    focus.aim(type, t.angle);
    t.guided = _guidedFromStart() || (repeat?.guided ?? false);
    _current = t;
    _missed = null;
    t.rift = RingRift(type: type, spawnAngle: t.angle, formDuration: _riftTime);
    parent.add(t.rift!);
    if (t.guided) {
      ghost.showFor(type, angleOfOrb: t.angle);
    }
    t.launchIn = _riftTime;
  }

  /// An empty dot whose orb makes the player turn the shield a fair bit
  /// (60° to 160°), or any empty dot if none fits
  int _pickDot(OrbType type) {
    final empty = [
      for (var i = 0; i < blocksToFinish; i++)
        if (!dots.isFilled(i)) i,
    ];
    double turnFor(int i) {
      final a = TutorialProgressDots.angleOf(i, blocksToFinish);
      final need = type == OrbType.fire ? a : a + pi;
      return _wrap(need - _fireAngle).abs();
    }

    final good = empty
        .where((i) => turnFor(i) > 60 * pi / 180 && turnFor(i) < 160 * pi / 180)
        .toList();
    final from = good.isNotEmpty ? good : empty;
    return from[_rnd.nextInt(from.length)];
  }

  void _launch(_Throw t) {
    final speed = t.guided ? _guidedSpeed : _soloSpeed;
    t.speed = speed;
    final orb = t.orb = spawner.spawnRhythmOrb(
      type: t.type,
      position: Vector2(cos(t.angle), sin(t.angle)) * (ArenaRing.radius + 10),
      speed: speed,
      onBlocked: () => _onBlocked(t),
      onHit: () => _onHit(t),
    );
    focus.track(orb);
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

    _holdOrResume(t, dt);
    _guide(t, active: !t.done);
  }

  /// The orb never hits the potato in the tutorial: it stops in front of
  /// the shields and trembles, with danger signs, until the right shield
  /// covers it, then flies on into it
  void _holdOrResume(_Throw t, double dt) {
    final orb = t.orb;
    if (orb == null || t.done || !orb.isFlying) {
      return;
    }
    final covered = _covered(t);
    if (t.holding) {
      if (covered) {
        t.holding = false;
        focus.held = false;
        orb.speed = t.speed;
        orb.position.setFrom(t.holdAt);
        return;
      }
      t.heldFor += dt;
      // A small shiver across its lane
      final shake = sin(t.heldFor * 45) * 1.6;
      orb.position
        ..setFrom(t.holdAt)
        ..add(Vector2(-sin(t.angle), cos(t.angle))..scale(shake));
      if (t.heldFor > _ghostAfter && !ghost.isShowing) {
        t.guided = true;
        ghost.showFor(t.type, angleOfOrb: t.angle);
      }
      return;
    }
    if (!covered && orb.position.length <= _holdDistance) {
      t.holding = true;
      focus.held = true;
      t.holdAt = Vector2(cos(t.angle), sin(t.angle))..scale(_holdDistance);
      orb.speed = 0;
      _audio.playNote('fire', 57, volume: 0.5);
    }
  }

  /// Keeps the ghost, its arrows and the button hint following the shield
  void _guide(_Throw t, {required bool active}) {
    ghost.from = t.type == OrbType.fire ? _fireAngle : _fireAngle - pi;
    final showHelp = ghost.isShowing && active;
    final covered = _covered(t);
    ghost.locked = covered;
    focus.covered = covered;
    if (showHelp && !covered) {
      bloc.setTutorialHint(_offBy(t) > 0 ? 1 : -1);
    } else {
      bloc.setTutorialHint(0);
    }
  }

  void _onBlocked(_Throw t) {
    if (t.done || !_active) {
      return;
    }
    t.done = true;
    _current = null;
    focus.clear();
    bloc.setTutorialHint(0);
    final note = _notes[_blocks.clamp(0, _notes.length - 1)];
    _blocks++;
    _lastWasHit = false;
    ghost.success();
    dots.fill(t.dot, t.type);
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
    focus.clear();
    bloc.setTutorialHint(0);
    _lastWasHit = true;
    dots.miss();
    // Keep the help where it is (or bring it in) without flashing anything
    // else, so the player can calmly turn the shield there
    if (!ghost.isShowing) {
      ghost.showFor(t.type, angleOfOrb: t.angle);
    }
    _missed = t;
    // The same orb again from the same spot, with help this time
    _wait = 1.1;
    _then = () {
      final again = _Throw(type: t.type, angle: t.angle, index: 0, dot: t.dot)
        ..guided = true;
      _throwNext(repeat: again);
    };
  }

  void _finish() {
    _finishing = true;
    bloc.setTutorialHint(0);
    ghost.hide();
    // The ring of dots glows, then swirls into the potato
    dots.celebrate();
    _audio.playNote('ice', 81 + 12, volume: 0.6);
    _wait = TutorialProgressDots.collapseEnd;
    _then = _celebrate;
  }

  /// The dots reached the potato: it pops, a wave and confetti fly out, a
  /// big tick shows over it and a rising arpeggio plays, then the real run
  /// starts with its music
  void _celebrate() {
    dots.hide();
    parent.add(TutorialCelebration());
    parent.player.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.22),
          EffectController(duration: 0.12, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.5, curve: Curves.elasticOut),
        ),
      ]),
    );
    parent.player.face.amazed();
    game.background.milestone();
    _arpeggio = 0;
    _arpeggioClock = 0;
    _wait = 1.5;
    _then = () {
      _active = false;
      bloc.finishTutorial();
    };
  }

  /// A minor, rising, ending on a two-note chord
  static const _arpeggioNotes = [69, 72, 76, 81, 84];
  int _arpeggio = -1;
  double _arpeggioClock = 0;

  void _playArpeggio(double dt) {
    if (_arpeggio < 0) {
      return;
    }
    _arpeggioClock -= dt;
    if (_arpeggioClock > 0) {
      return;
    }
    final note = _arpeggioNotes[_arpeggio];
    _audio.playNote(_arpeggio.isEven ? 'ice' : 'fire', note + 12, volume: 0.8);
    _arpeggio++;
    _arpeggioClock = 0.075;
    if (_arpeggio >= _arpeggioNotes.length) {
      _audio.playNote('ice', 88 + 12, volume: 0.6);
      _arpeggio = -1;
    }
  }

  // ------------------------------------------------------------------
  // Bot, for videos (`?tutorialbot=1`)

  final _bot = _TutorialBot();
}

class _Throw {
  _Throw({
    required this.type,
    required this.angle,
    required this.index,
    required this.dot,
  });

  final OrbType type;
  final double angle;
  final int index;

  /// The progress dot this orb fills when blocked
  final int dot;

  bool guided = false;
  bool done = false;
  MovingOrb? orb;
  double speed = 0;
  bool holding = false;
  double heldFor = 0;
  Vector2 holdAt = Vector2.zero();
  double? launchIn;
  double? closeRiftIn;
  RingRift? rift;
}

/// Plays like a new player: misses on purpose a couple of times, otherwise
/// turns the shield after a short reaction time
class _TutorialBot {
  _Throw? _seen;
  double _react = 0;
  int _held = 0;

  /// Throws the bot reacts to late, to show the orb waiting with danger
  /// signs
  static const _lateThrows = {1, 4};

  void update(TutorialDirector d, double dt) {
    final t = d._current;
    if (t == null || t.done) {
      _press(d, 0);
      return;
    }
    if (_seen != t) {
      _seen = t;
      _react = _lateThrows.contains(t.index) ? 4.5 : 1.0;
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
