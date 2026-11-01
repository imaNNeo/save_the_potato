import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/presentation/components/moving/moving_component_spawner.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

import 'orb_sides.dart';
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

  /// Thrown, but not through their rift yet
  final _passing = <_PlannedOrb>[];
  int _nextBeat = 0;
  final _sides = OrbSides();
  int _beatsUntilHeartCheck = 8;

  /// Orb hitbox radius (17 / 2) plus the outer radius of the shield
  static const _contactDistance = 8.5 + 68.0;

  /// The orb starts moving a frame after it is added, and a block is only
  /// seen on the frame after the hitboxes touch
  static const _mountDelay = 0.03;

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
        _passing.clear();
    }
  }

  bool _running = false;

  void _startRun() {
    _running = true;
    _songTime = 0;
    _audioTime = 0;
    _lastPosition = null;
    _planned.clear();
    _passing.clear();
    _inFlight.clear();
    // Give the player a moment before the first orb lands
    _nextBeat = 4;
    _sides.reset();
    _beatsUntilHeartCheck = 8;
  }

  // ------------------------------------------------------------------
  // Clock

  static const _loopEnd = RhythmSongs.loopSeconds;

  void _tickClock(double dt) {
    final position = _audio.musicPosition;
    if (position == null) {
      // Muted: run on game time
      _songTime += dt;
      _lastPosition = null;
      return;
    }
    if (_lastPosition == null && _songTime > 0.5) {
      // The music just started mid-run (it was muted): move the music to
      // where the game is, instead of rewinding the game to the music
      final at = (_songTime + dt) % _loopEnd;
      _audio.seekMusic(at);
      _songTime += dt;
      _audioTime = _songTime;
      _lastPosition = at;
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
    final lookahead = _flightTime(speed, _spawnRadius) + _maxFormTime + 0.3;
    while (_beatTime(_nextBeat) < _songTime + lookahead) {
      _planBeat(_nextBeat, speed);
      _nextBeat++;
    }

    // Rifts open ahead of the orb reaching the ring, so the player sees
    // where it comes in, and snap shut once it is through
    for (final orb in _planned) {
      if (orb.portalAt <= _songTime) {
        _openPortal(orb);
      }
    }
    for (final orb in _passing) {
      if (orb.portalAt <= _songTime) {
        _openPortal(orb);
      }
    }
    _passing.removeWhere((orb) {
      // A moment after its middle reaches the ring, so its tail is through
      if (orb.throughAt + 0.1 > _songTime) {
        return false;
      }
      _openPortal(orb);
      orb.portal!.close();
      return true;
    });

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

  // ---- rifts (the tears in the arena ring the orbs come through) ----

  /// Orbs start this far out, hidden outside the arena ring, and fly in
  /// through their rift
  static const _spawnRadius = ArenaRing.radius + _hiddenRun;

  /// How far they fly unseen before they reach the ring
  static const _hiddenRun = 90.0;

  static const _maxFormTime = RingRift.maxFormDuration;

  @override
  void onMount() {
    super.onMount();
    parent.add(ArenaRingComponent());
  }

  void _openPortal(_PlannedOrb orb) {
    if (orb.portal != null) {
      return;
    }
    final ahead = max(0.05, orb.throughAt - _songTime);
    final rift = RingRift(
      type: orb.type,
      spawnAngle: orb.angle,
      formDuration: ahead,
    );
    parent.add(rift);
    orb.portal = rift;
  }

  void _launch(_PlannedOrb orb, {required double late}) {
    if (late > 0.25) {
      // Too late to fly in properly, skip it
      orb.portal?.close();
      return;
    }
    _passing.add(orb);
    orb.thrownAngle = orb.angle;
    if (autopilot) {
      _inFlight.add(orb);
    }
    final distance = max(_contactDistance + 4, orb.radius - orb.speed * late);
    spawner.spawnRhythmOrb(
      type: orb.type,
      position: Vector2(cos(orb.angle), sin(orb.angle)) * distance,
      speed: orb.speed,
      rhythmHit: orb.hit,
    );
  }

  // ------------------------------------------------------------------
  // Planning

  void _planBeat(int beat, double speed) {
    _maybePlanHeart();
    _planMelodyBeat(beat, speed);
  }

  void _maybePlanHeart() {
    _beatsUntilHeartCheck--;
    if (_beatsUntilHeartCheck > 0) {
      return;
    }
    _beatsUntilHeartCheck = 4;
    if (!spawner.hasMovingHealth) {
      spawner.tryToSpawnHealthPoint();
    }
  }

  double get _difficulty => bloc.state.difficulty;

  /// The difficulty each melody note joins in at. The first note of each
  /// bar is always there. The other notes on a beat join one by one between
  /// [_beatNotesFrom] and [_beatNotesTo], then the notes between beats
  /// between [_offbeatNotesFrom] and [_offbeatNotesTo]. So the song fills in
  /// gradually instead of doubling all at once.
  static final Map<MelodyNote, double> _noteJoinsAt = () {
    final joins = <MelodyNote, double>{};
    for (final (tier, from, to) in [
      (1, _beatNotesFrom, _beatNotesTo),
      (2, _offbeatNotesFrom, _offbeatNotesTo),
    ]) {
      final notes = RhythmSongs.melody.where((n) => n.tier == tier).toList()
        // A fixed shuffle, so they join spread over the song, not bar by bar
        ..shuffle(Random(tier));
      for (var i = 0; i < notes.length; i++) {
        joins[notes[i]] = from + (to - from) * (i + 0.5) / notes.length;
      }
    }
    return joins;
  }();

  static const _beatNotesFrom = 0.12;
  static const _beatNotesTo = 0.45;
  static const _offbeatNotesFrom = 0.5;
  static const _offbeatNotesTo = 0.85;

  bool _notePlays(MelodyNote note) =>
      note.tier == 0 || _difficulty >= (_noteJoinsAt[note] ?? 0);

  /// Picks where an orb comes from: fire orbs in one group, ice orbs in
  /// one group on the opposite side, see [OrbSides]
  double _pickAngle(OrbType type, double land) =>
      _sides.angleFor(type, land, _difficulty);

  void _add(double land, OrbType type, double speed, {RhythmHit? hit}) {
    final radius = _spawnRadius;
    final launchAt = land - _flightTime(speed, radius) - _mountDelay;
    final formDuration = RingRift.formDurationFor(_difficulty);
    _planned.add(
      _PlannedOrb(
        land: land,
        launchAt: launchAt,
        throughAt: launchAt + _hiddenRun / speed,
        portalAt: launchAt + _hiddenRun / speed - formDuration,
        type: type,
        angle: _pickAngle(type, land),
        radius: radius,
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
      if (!_notePlays(note)) {
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
    required this.throughAt,
    required this.type,
    required this.angle,
    required this.radius,
    required this.speed,
    this.hit,
  }) : thrownAngle = angle;

  /// Song times: when it hits the shield, when it starts flying (unseen,
  /// outside the ring), when its rift starts to open, and when it is
  /// through the ring
  final double land, launchAt, portalAt, throughAt;
  final OrbType type;

  /// Where it should leave from, and how far out
  final double angle, radius;
  final double speed;
  final RhythmHit? hit;
  RingRift? portal;
  double thrownAngle;
}
