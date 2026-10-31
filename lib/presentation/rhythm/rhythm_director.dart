import 'dart:convert';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:save_the_potato/presentation/components/moving/moving_component_spawner.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/service_locator.dart';

import 'beat_map.dart';
import 'rhythm_hit.dart';
import 'rhythm_mode.dart';
import 'rhythm_songs.dart';

/// Rhythm prototype. Reads the music position as the game clock, plans
/// where every orb should land on the beat, and launches each one early by
/// its flight time so the block happens exactly on that beat.
class RhythmDirector extends Component
    with
        HasGameReference<PotatoGame>,
        ParentIsA<MyWorld>,
        FlameBlocListenable<GameCubit, GameState> {
  RhythmDirector({required this.spawner});

  final MovingComponentSpawner spawner;

  final _audio = getIt.get<AudioHelper>();
  final _rnd = Random();

  /// The mode of the current run; the picker only applies on the next run
  RhythmMode _mode = RhythmMode.off;

  bool get isActive => _mode != RhythmMode.off;

  /// Logs how far each block lands from its beat (`?rhythmlog=1` on web)
  static final logTiming =
      kIsWeb && Uri.base.queryParameters['rhythmlog'] == '1';

  /// Test autopilot that turns the shield to every orb (`?rhythmbot=1`)
  static final autopilot =
      kIsWeb && Uri.base.queryParameters['rhythmbot'] == '1';
  final _inFlight = <_PlannedOrb>[];

  late final BeatMap _gameMusicBeats;

  // ---- clock ----
  double _songTime = 0;
  double _audioTime = 0;
  double? _lastPosition;

  // ---- planning ----
  final _planned = <_PlannedOrb>[];
  int _nextBeat = 0;
  int _beatsUntilSingle = 0;
  _Wave? _wave;
  double _lastLand = -10;
  double _lastShieldAngle = 0;
  int _beatsUntilHeartCheck = 8;

  // ---- streak song ----
  int _streak = 0;
  double _dipTimer = 0;

  /// Orb hitbox radius (17 / 2) plus the outer radius of the shield
  static const _contactDistance = 8.5 + 68.0;

  /// The orb starts moving a frame after it is added, and a block is only
  /// seen on the frame after the hitboxes touch
  static const _mountDelay = 0.03;

  static const _shieldTurnSpeed = pi * 1.8;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _gameMusicBeats = BeatMap.fromJson(
      jsonDecode(
        await rootBundle.loadString('assets/audio/rhythm/bg_beats.json'),
      ) as Map<String, dynamic>,
    );
  }

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
        _mode = RhythmMode.off;
        _planned.clear();
    }
  }

  bool _running = false;

  void _startRun() {
    _running = true;
    _mode = RhythmMode.current.value;
    _songTime = 0;
    _audioTime = 0;
    _lastPosition = null;
    _planned.clear();
    _inFlight.clear();
    // Give the player a moment before the first orb lands
    _nextBeat = 4;
    _beatsUntilSingle = 2;
    _wave = null;
    _lastLand = -10;
    _lastShieldAngle = _rnd.nextDouble() * pi * 2;
    _beatsUntilHeartCheck = 8;
    _streak = 0;
    _dipTimer = 0;
    final levels = switch (_mode) {
      RhythmMode.melody => RhythmSongs.melodyLayers,
      RhythmMode.drumBell => RhythmSongs.drumBellLayers,
      RhythmMode.streakSong => RhythmSongs.streakLayersFor(0),
      _ => const <String>{},
    };
    _applyLayers(levels, fadeSeconds: 0);
  }

  // ------------------------------------------------------------------
  // Clock

  double get _loopStart => _mode.usesStems ? 0 : _gameMusicBeats.loopStart;

  double get _loopEnd =>
      _mode.usesStems ? RhythmSongs.loopSeconds : _gameMusicBeats.duration;

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
        delta = (_loopEnd - _lastPosition!) + (position - _loopStart);
      }
      _audioTime += max(0, delta);
    }
    _lastPosition = position;
    final predicted = _songTime + dt;
    final error = _audioTime - predicted;
    _songTime = error.abs() > 0.08 ? _audioTime : predicted + error * 0.15;
  }

  double _beatTime(int beat) => _mode.usesStems
      ? beat * RhythmSongs.beatSeconds
      : _gameMusicBeats.beatTime(beat);

  // ------------------------------------------------------------------
  // Frame

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive || !bloc.state.playingState.isPlaying) {
      return;
    }
    _tickClock(dt);

    if (_dipTimer > 0) {
      _dipTimer -= dt;
      if (_dipTimer <= 0) {
        _applyLayers(RhythmSongs.streakLayersFor(_streak), fadeSeconds: 1.2);
      }
    }

    final speed = _orbSpeed;
    final flight = _flightTime(speed);
    while (_beatTime(_nextBeat) < _songTime + flight + 0.4) {
      _planBeat(_nextBeat, speed);
      _nextBeat++;
    }

    while (_planned.isNotEmpty) {
      final next = _planned.first;
      final launchAt = next.land - _flightTime(next.speed) - _mountDelay;
      if (launchAt > _songTime) {
        break;
      }
      _planned.removeAt(0);
      _launch(next, late: _songTime - launchAt);
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
    final need = next.type == OrbType.fire ? next.angle : next.angle + pi;
    parent.player.fireShield.angle = need;
  }

  double get _orbSpeed =>
      const GameModeSingleSpawn().getSpawnOrbsMoveSpeed(bloc.state.difficulty);

  double _flightTime(double speed) =>
      (spawner.spawnDistance - _contactDistance) / speed;

  void _launch(_PlannedOrb orb, {required double late}) {
    if (late > 0.25) {
      // Too late to fly in properly, skip it
      return;
    }
    if (autopilot) {
      _inFlight.add(orb);
    }
    final distance = max(
      _contactDistance + 4,
      spawner.spawnDistance - orb.speed * late,
    );
    spawner.spawnRhythmOrb(
      type: orb.type,
      position: Vector2(cos(orb.angle), sin(orb.angle)) * distance,
      speed: orb.speed,
      rhythmHit: orb.hit,
      overrideCollisionSoundNumber: orb.overrideSound,
    );
  }

  // ------------------------------------------------------------------
  // Planning

  void _planBeat(int beat, double speed) {
    _maybePlanHeart();
    switch (_mode) {
      case RhythmMode.onBeat || RhythmMode.inKey:
        _planGameMusicBeat(beat, speed);
      case RhythmMode.melody:
        _planMelodyBeat(beat, speed);
      case RhythmMode.drumBell:
        _planDrumBeat(beat, speed);
      case RhythmMode.streakSong:
        _planStreakBeat(beat, speed);
      case RhythmMode.off:
        break;
    }
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

  void _add(
    double land,
    OrbType type,
    double speed, {
    RhythmHit? hit,
    int? overrideSound,
    double? angle,
  }) {
    _planned.add(
      _PlannedOrb(
        land: land,
        type: type,
        angle: angle ?? _pickAngle(type, land),
        speed: speed,
        hit: hit,
        overrideSound: overrideSound,
      ),
    );
    _planned.sort((a, b) => a.land.compareTo(b.land));
  }

  OrbType _randomType() => OrbType.values[_rnd.nextInt(2)];

  // ---- the current music: on the beat / in key ----

  void _planGameMusicBeat(int beat, double speed) {
    final t = _beatTime(beat);
    final beatLength = _beatTime(beat + 1) - t;
    final wave = _wave;
    if (wave != null) {
      _planWaveBeat(wave, beat, t, beatLength, speed);
      return;
    }
    _beatsUntilSingle--;
    if (_beatsUntilSingle > 0) {
      return;
    }
    final every = const GameModeSingleSpawn().getSpawnOrbsEvery(_difficulty);
    _beatsUntilSingle = max(1, (every / beatLength).round());

    // Same odds as today's waves: half way up the difficulty, now and then
    if (_difficulty >= 0.5 && _rnd.nextDouble() < 0.07) {
      _wave = _Wave(series: 2 + _rnd.nextInt(4));
      _planWaveBeat(_wave!, beat, t, beatLength, speed);
      return;
    }
    final type = _randomType();
    _add(t, type, speed, hit: _gameMusicHit(type, beat, t, 0));
  }

  /// [arpeggio] 0 is a single orb, 1.. is the position in a wave
  RhythmHit _gameMusicHit(
    OrbType type,
    int beat,
    double land,
    int arpeggio, {
    bool silent = false,
  }) {
    if (_mode == RhythmMode.onBeat) {
      // Today's chord sounds; -1 means the hit counter picks one as today
      return RhythmHit(
        timbre: 'chord',
        midi: arpeggio == 0 ? -1 : (arpeggio - 1) % 6,
        land: land,
        silent: silent,
      );
    }
    final chord = _gameMusicBeats.chordAt(beat);
    final pitchClass = arpeggio == 0
        ? _gameMusicBeats.pitchAt(beat)
        : chord[(arpeggio - 1) % 3] + 12 * ((arpeggio - 1) ~/ 3);
    var midi = (type == OrbType.fire ? 60 : 72) + pitchClass;
    if (midi > (type == OrbType.fire ? 74 : 86)) {
      midi -= 12;
    }
    return RhythmHit(
      timbre: type == OrbType.fire ? 'fire' : 'ice',
      midi: midi,
      land: land,
      silent: silent,
    );
  }

  /// Today's multi spawn wave, one orb per beat (or half beat when hard),
  /// sometimes mirrored by a silent twin of the other colour
  void _planWaveBeat(
    _Wave wave,
    int beat,
    double t,
    double beatLength,
    double speed,
  ) {
    if (wave.restBeats > 0) {
      wave.restBeats--;
      if (wave.restBeats == 0 && wave.series == 0) {
        _wave = null;
        _beatsUntilSingle = 2;
      }
      return;
    }
    if (wave.orbsLeft == 0) {
      wave.orbsLeft = 6;
      wave.type = _randomType();
      wave.angle = _pickAngle(wave.type, t);
      wave.mirrored = _rnd.nextDouble() <= 2 / 3;
      wave.halfBeats = _difficulty > 0.8;
    }
    final steps = wave.halfBeats ? [0.0, 0.5] : [0.0];
    for (final step in steps) {
      if (wave.orbsLeft == 0) {
        break;
      }
      final land = t + step * beatLength;
      final index = 6 - wave.orbsLeft;
      final hit = _gameMusicHit(wave.type, beat, land, index + 1);
      _add(land, wave.type, speed, angle: wave.angle, hit: hit);
      if (wave.mirrored) {
        final twin = wave.type == OrbType.fire ? OrbType.ice : OrbType.fire;
        _add(
          land,
          twin,
          speed,
          angle: wave.angle + pi,
          hit: _gameMusicHit(twin, beat, land, index + 1, silent: true),
        );
      }
      wave.orbsLeft--;
    }
    _lastLand = t;
    if (wave.orbsLeft == 0) {
      wave.series--;
      wave.restBeats = 2;
    }
  }

  // ---- new songs ----

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
          bar: bar,
          land: land,
        ),
      );
    }
  }

  void _planDrumBeat(int beat, double speed) {
    final bar = _barOf(beat);
    final patterns = RhythmSongs.drumPatterns[_tier];
    final pattern = patterns[bar % patterns.length];
    final chord = RhythmSongs.chordOfBar(bar);
    final beatInBar = beat % 4;
    for (var half = 0; half < 2; half++) {
      final step = beatInBar * 2 + half;
      final c = pattern[step];
      if (c == '.') {
        continue;
      }
      final land = _beatTime(beat) + half * RhythmSongs.beatSeconds / 2;
      final fire = c == 'F';
      _add(
        land,
        fire ? OrbType.fire : OrbType.ice,
        speed,
        hit: fire
            ? RhythmHit(
                timbre: 'boom',
                midi: chord.root + 12,
                bar: bar,
                land: land,
              )
            : RhythmHit(
                timbre: 'ting',
                midi: chord.voicing[(step ~/ 2) % 3] + 24,
                bar: bar,
                land: land,
              ),
      );
    }
  }

  void _planStreakBeat(int beat, double speed) {
    _beatsUntilSingle--;
    final t = _beatTime(beat);
    if (_beatsUntilSingle <= 0) {
      final every = const GameModeSingleSpawn().getSpawnOrbsEvery(_difficulty);
      _beatsUntilSingle = max(
        1,
        (every / RhythmSongs.beatSeconds).round(),
      ).clamp(1, 4);
      _addStreakOrb(t, beat, speed);
    }
    if (_difficulty > 0.75 && beat % 4 == 1) {
      _addStreakOrb(t + RhythmSongs.beatSeconds / 2, beat, speed);
    }
  }

  void _addStreakOrb(double land, int beat, double speed) {
    final type = _randomType();
    _add(
      land,
      type,
      speed,
      hit: RhythmHit(
        timbre: type == OrbType.fire ? 'fire' : 'ice',
        bar: _barOf(beat),
        land: land,
      ),
    );
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
    if (_mode == RhythmMode.streakSong) {
      _streak++;
      final chord = RhythmSongs.chordOfBar(hit.bar);
      final pool = chord.climbPool;
      final k = _streak - 1;
      final midi = k < pool.length ? pool[k] : pool[pool.length - 3 + k % 3];
      _audio.playNote(
        hit.timbre,
        hit.timbre == 'ice' ? midi + 12 : midi,
        pan: pan,
      );
      final unlocked = RhythmSongs.streakUnlocks.contains(_streak);
      if (unlocked) {
        _audio.playNote('ice', midi + 24, volume: 0.6);
      }
      if (_dipTimer <= 0) {
        _applyLayers(RhythmSongs.streakLayersFor(_streak), fadeSeconds: 0.25);
      }
      return;
    }
    if (hit.silent) {
      return;
    }
    if (hit.timbre == 'chord') {
      _audio.playShieldSound(
        hit.midi >= 0 ? hit.midi : bloc.state.shieldHitCounter,
      );
      return;
    }
    _audio.playNote(hit.timbre, hit.midi, pan: pan);
  }

  /// An orb got through to the potato
  void onMissed() {
    if (_mode != RhythmMode.streakSong) {
      return;
    }
    _streak = 0;
    // Strip the song back and duck what is left for a moment
    _applyLayers(const {}, fadeSeconds: 0.08, base: 0.35);
    _dipTimer = 0.5;
  }

  void _applyLayers(
    Set<String> on, {
    required double fadeSeconds,
    double base = 1,
  }) {
    for (final name in AudioHelper.rhythmStems) {
      final level = RhythmSongs.alwaysOn(_mode).contains(name)
          ? base
          : (on.contains(name) ? 1.0 : 0.0);
      _audio.setStemLevel(name, level, fadeSeconds: fadeSeconds);
    }
  }
}

class _PlannedOrb {
  _PlannedOrb({
    required this.land,
    required this.type,
    required this.angle,
    required this.speed,
    this.hit,
    this.overrideSound,
  });

  final double land;
  final OrbType type;
  final double angle;
  final double speed;
  final RhythmHit? hit;
  final int? overrideSound;
}

class _Wave {
  _Wave({required this.series});

  int series;
  int orbsLeft = 0;
  int restBeats = 0;
  OrbType type = OrbType.fire;
  double angle = 0;
  bool mirrored = false;
  bool halfBeats = false;
}
