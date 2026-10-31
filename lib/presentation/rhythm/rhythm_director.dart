import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/presentation/components/moving/moving_component_spawner.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/moving/portal/orb_portal.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

import 'rhythm_hit.dart';
import 'rhythm_songs.dart';

/// "Shield plays the melody": reads the music position as the game clock,
/// plans an orb for every melody note of the song, and launches each one
/// early by its flight time so the block plays that note right on time.
class RhythmDirector extends Component
    with
        HasGameReference<PotatoGame>,
        ParentIsA<MyWorld>,
        FlameBlocListenable<GameCubit, GameState> {
  RhythmDirector({required this.spawner});

  final MovingComponentSpawner spawner;

  final _audio = getIt.get<AudioHelper>();
  final _rnd = Random();

  /// Logs how far each block lands from its beat (`?rhythmlog=1` on web)
  static final logTiming =
      kIsWeb && Uri.base.queryParameters['rhythmlog'] == '1';

  /// Test autopilot that turns the shield to every orb (`?rhythmbot=1`)
  static final autopilot =
      kIsWeb && Uri.base.queryParameters['rhythmbot'] == '1';
  final _inFlight = <_PlannedOrb>[];

  // ---- clock ----
  double _songTime = 0;
  double _audioTime = 0;
  double? _lastPosition;

  // ---- planning ----
  final _planned = <_PlannedOrb>[];
  int _nextBeat = 0;
  double _lastLand = -10;
  double _lastShieldAngle = 0;

  /// Orb hitbox radius (17 / 2) plus the outer radius of the shield
  static const _contactDistance = 8.5 + 68.0;

  /// The orb starts moving a frame after it is added, and a block is only
  /// seen on the frame after the hitboxes touch
  static const _mountDelay = 0.03;

  static const _shieldTurnSpeed = pi * 1.8;

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    switch (state.playingState) {
      case PlayingStatePlaying():
        if (!_running) {
          _startRun();
        }
      case PlayingStatePaused():
        break;
      case PlayingStateGuide() || PlayingStateGameOver() || PlayingStateNone():
        _running = false;
        _planned.clear();
    }
  }

  bool _running = false;

  void _startRun() {
    _running = true;
    _songTime = 0;
    _audioTime = 0;
    _lastPosition = null;
    _planned.clear();
    _inFlight.clear();
    // Give the player a moment before the first orb lands
    _nextBeat = 4;
    _lastLand = -10;
    _lastShieldAngle = _rnd.nextDouble() * pi * 2;
  }

  // ------------------------------------------------------------------
  // Clock

  static const _loopEnd = RhythmSongs.loopSeconds;

  void _tickClock(double dt) {
    final position = _audio.musicPosition;
    if (position == null) {
      // Muted: run on game time
      _songTime += dt;
      return;
    }
    if (_lastPosition == null) {
      _audioTime = position;
    } else {
      var delta = position - _lastPosition!;
      if (delta < -0.5) {
        // The music looped
        delta = (_loopEnd - _lastPosition!) + position;
      }
      _audioTime += max(0, delta);
    }
    _lastPosition = position;
    final predicted = _songTime + dt;
    final error = _audioTime - predicted;
    _songTime = error.abs() > 0.08 ? _audioTime : predicted + error * 0.15;
  }

  double _beatTime(int beat) => beat * RhythmSongs.beatSeconds;

  // ------------------------------------------------------------------
  // Frame

  @override
  void update(double dt) {
    super.update(dt);
    if (!_running || !bloc.state.playingState.isPlaying) {
      return;
    }
    _tickClock(dt);

    final speed = _orbSpeed;
    final lookahead = _flightTime(speed, _maxPortalRadius) + _maxFormTime + 0.3;
    while (_beatTime(_nextBeat) < _songTime + lookahead) {
      _planBeat(_nextBeat, speed);
      _nextBeat++;
    }

    // Portals form ahead of their throw, so the player sees them coming
    for (final orb in _planned) {
      if (orb.portalAt <= _songTime) {
        _openPortal(orb);
      }
    }

    while (_planned.isNotEmpty) {
      final next = _planned.first;
      if (next.launchAt > _songTime) {
        break;
      }
      _planned.removeAt(0);
      _launch(next, late: _songTime - next.launchAt);
    }

    if (autopilot) {
      _steer();
    }
  }

  void _steer() {
    _inFlight.removeWhere((o) => o.land < _songTime - 0.15);
    if (_inFlight.isEmpty) {
      return;
    }
    final next = _inFlight.first;
    final angle = next.thrownAngle;
    final need = next.type == OrbType.fire ? angle : angle + pi;
    parent.player.fireShield.angle = need;
  }

  double get _orbSpeed =>
      const GameModeSingleSpawn().getSpawnOrbsMoveSpeed(bloc.state.difficulty);

  double _flightTime(double speed, double radius) =>
      (radius - _contactDistance) / speed;

  // ---- portals (the white holes the orbs come out of) ----

  static const _maxPortalRadius = 225.0;
  static const _maxFormTime = PortalMove.maxFormDuration;

  void _openPortal(_PlannedOrb orb) {
    if (orb.portal != null) {
      return;
    }
    // Starts back along its glide, so it ends up at the planned spot
    final ahead = max(0.05, orb.launchAt - _songTime);
    final move = orb.move;
    final angle = orb.angle - move.travel;
    parent.add(
      orb.portal = OrbPortal(
        type: orb.type,
        position: Vector2(cos(angle), sin(angle)) * orb.radius,
        formDuration: ahead,
        travel: move.travel,
        travelTime: min(move.travelTime, ahead),
      ),
    );
  }

  void _launch(_PlannedOrb orb, {required double late}) {
    _openPortal(orb);
    final portal = orb.portal!;
    portal.close();
    if (late > 0.25) {
      // Too late to fly in properly, skip it
      return;
    }
    // Leaves from where the portal is now, it may have drifted a little
    orb.thrownAngle = atan2(portal.position.y, portal.position.x);
    if (autopilot) {
      _inFlight.add(orb);
    }
    final distance = max(_contactDistance + 4, orb.radius - orb.speed * late);
    spawner.spawnRhythmOrb(
      type: orb.type,
      position: Vector2(cos(orb.thrownAngle), sin(orb.thrownAngle)) * distance,
      speed: orb.speed,
      rhythmHit: orb.hit,
    );
  }

  // ------------------------------------------------------------------
  // Planning

  void _planBeat(int beat, double speed) {
    _planMelodyBeat(beat, speed);
  }

  double get _difficulty => bloc.state.difficulty;

  /// 0: only the strongest notes, 1: every beat note, 2: everything
  int get _tier => _difficulty < 0.3 ? 0 : (_difficulty < 0.6 ? 1 : 2);

  /// Picks where an orb comes from so the shield can actually get there
  /// from where the last orb needed it
  double _pickAngle(OrbType type, double land) {
    final gap = land - _lastLand;
    final maxTurn = min(pi, max(0.35, 0.55 * _shieldTurnSpeed * gap));
    _lastShieldAngle += (_rnd.nextDouble() * 2 - 1) * maxTurn;
    _lastLand = land;
    return switch (type) {
      OrbType.fire => _lastShieldAngle,
      OrbType.ice => _lastShieldAngle + pi,
    };
  }

  void _add(double land, OrbType type, double speed, {RhythmHit? hit}) {
    final radius = 185 + _rnd.nextDouble() * 40;
    final launchAt = land - _flightTime(speed, radius) - _mountDelay;
    final move = PortalMove.random(_difficulty, random: _rnd);
    _planned.add(
      _PlannedOrb(
        land: land,
        launchAt: launchAt,
        portalAt: launchAt - move.formDuration,
        type: type,
        angle: _pickAngle(type, land),
        radius: radius,
        move: move,
        speed: speed,
        hit: hit,
      ),
    );
    _planned.sort((a, b) => a.launchAt.compareTo(b.launchAt));
  }

  // ---- the song ----

  int _barOf(int beat) => beat ~/ 4;

  void _planMelodyBeat(int beat, double speed) {
    final bar = _barOf(beat);
    final beatInBar = beat % 4;
    for (final note in RhythmSongs.melody) {
      if (note.bar != bar % RhythmSongs.bars) {
        continue;
      }
      if (note.beat.floor() != beatInBar) {
        continue;
      }
      if (note.tier > _tier) {
        continue;
      }
      final land = _beatTime(beat) + (note.beat - beatInBar) * 0.5;
      final ice = note.midi >= 74;
      final type = ice ? OrbType.ice : OrbType.fire;
      _add(
        land,
        type,
        speed,
        hit: RhythmHit(
          timbre: ice ? 'ice' : 'fire',
          midi: ice ? note.midi : note.midi - 12,
          land: land,
        ),
      );
    }
  }

  // ------------------------------------------------------------------
  // Hits

  /// The shield blocked an orb that carries a [RhythmHit]
  void onBlocked(MovingOrb orb, RhythmHit hit) {
    if (logTiming) {
      final ms = ((_songTime - hit.land) * 1000).round();
      debugPrint('rhythm block ${hit.timbre} off by ${ms}ms');
    }
    final pan = cos(atan2(orb.position.y, orb.position.x)) * 0.5;
    _audio.playNote(hit.timbre, hit.midi, pan: pan);
  }
}

class _PlannedOrb {
  _PlannedOrb({
    required this.land,
    required this.launchAt,
    required this.portalAt,
    required this.type,
    required this.angle,
    required this.radius,
    required this.move,
    required this.speed,
    this.hit,
  }) : thrownAngle = angle;

  /// Song times: when it hits the shield, leaves its portal, and the portal
  /// starts to form
  final double land, launchAt, portalAt;
  final OrbType type;

  /// Where it should leave from, and how far out
  final double angle, radius;

  /// How its own portal moves before the throw
  final PortalMove move;
  final double speed;
  final RhythmHit? hit;
  OrbPortal? portal;
  double thrownAngle;
}
