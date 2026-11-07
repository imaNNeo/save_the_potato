import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/presentation/components/level_progress/level_progress_ring.dart';
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
      previousState.playingState != newState.playingState ||
      previousState.tutorial != newState.tutorial;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    switch (state.playingState) {
      case PlayingStatePlaying():
        // The tutorial throws its own orbs, the song starts after it
        if (!_running && !state.tutorial) {
          _startRun();
        }
      case PlayingStatePaused():
        break;
      case PlayingStateGuide() ||
          PlayingStateGameOver() ||
          PlayingStateLevelCleared() ||
          PlayingStateNone():
        _running = false;
        _planned.clear();
        _passing.clear();
    }
  }

  bool _running = false;

  /// The song of this run: the infinite song, or the level's
  Song _song = RhythmSongs.song;

  /// Whether the level's song has ended and the level is cleared
  bool _ended = false;

  /// Whether the level's music has played its last note
  bool _musicEnded = false;

  /// Whether a run is going and [songTime] follows the music
  bool get isRunning => _running;

  /// Where the song is, in seconds (beats land on multiples of
  /// the song's beatSeconds)
  double get songTime => _songTime;

  void _startRun() {
    _running = true;
    _song = bloc.state.song;
    _ended = false;
    _musicEnded = false;
    // A level starts with its intro, before the tune's first beat at 0
    _songTime = -_song.introSeconds;
    _audioTime = _songTime;
    _lastPosition = null;
    _planned.clear();
    _passing.clear();
    _inFlight.clear();
    // Give the player a moment before the first orb lands. A level's
    // intro gives it, so a tune starts from its very first note.
    _nextBeat = _song.introBars > 0 ? -_song.introBars * _song.beatsPerBar : 4;
    _sides.reset();
    _beatsUntilHeartCheck = 8;
    _stageOfLoop.clear();
    _layersLoop = -1;
    _skipAhead();
  }

  /// Preview only: `?from=0.9` starts a level's song 90% in, to see its
  /// end without playing it all
  void _skipAhead() {
    final duration = _song.durationSeconds;
    final from = kIsWeb
        ? double.tryParse(Uri.base.queryParameters['from'] ?? '')
        : null;
    if (duration == null || from == null || from <= 0) {
      return;
    }
    _songTime = duration * from.clamp(0.0, 0.99);
    _audioTime = _songTime;
    _nextBeat = (_songTime / _song.beatSeconds).ceil() + 2;
  }

  // ------------------------------------------------------------------
  // Clock

  double get _loopEnd => _song.loopSeconds;

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
      // In the intro the music plays the end of the loop, before 0
      _audioTime = _songTime < _loopEnd / 4 && position > _loopEnd / 2
          ? position - _loopEnd
          : position;
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

  double _beatTime(int beat) => beat * _song.beatSeconds;

  // ------------------------------------------------------------------
  // Frame

  @override
  void update(double dt) {
    super.update(dt);
    if (!_running || !bloc.state.playingState.isPlaying) {
      return;
    }
    _tickClock(dt);
    _updateLayers();

    final speed = _orbSpeed;
    final lookahead = _flightTime(speed, _spawnRadius) + _maxFormTime + 0.3;
    final totalBeats = _song.totalBeats;
    while (_beatTime(_nextBeat) < _songTime + lookahead &&
        (totalBeats == null || _nextBeat < totalBeats)) {
      _planBeat(_nextBeat, speed);
      _nextBeat++;
    }
    final endBeat = _song.endBeat;
    if (endBeat != null &&
        !_musicEnded &&
        _songTime >= endBeat * _song.beatSeconds) {
      // The tune's last note: the music stops right on it, with the
      // final chord
      _musicEnded = true;
      _audio.endMusic(_song.finale);
    }
    if (endBeat != null &&
        !_ended &&
        _songTime > endBeat * _song.beatSeconds + _clearDelay) {
      // The level's song is over, and its last orbs are blocked
      _ended = true;
      bloc.levelCleared();
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

  double get _orbSpeed => const GameModeSingleSpawn().getSpawnOrbsMoveSpeed(
    bloc.state.difficulty,
    overdrive: _overdrive,
  );

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
    parent.add(LevelProgressRing(director: this));
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

  /// How long after the last beat of a level's song it is cleared, so its
  /// last orbs land first
  static const _clearDelay = 1.0;

  /// How late an orb may still launch, from a bit closer in
  static const _maxLate = 0.25;

  void _launch(_PlannedOrb orb, {required double late}) {
    if (late > _maxLate) {
      // Too late to fly in properly, skip it
      orb.portal?.close();
      return;
    }
    _passing.add(orb);
    orb.thrownAngle = orb.angle;
    if (autopilot && !(orb.hit?.companion ?? false)) {
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

  /// How far past the peak difficulty the run is (0 to 1)
  double get _overdrive => bloc.state.overdrive;

  /// The difficulty each melody note of each phrase joins in at. The first
  /// note of each bar is always there. The other notes on a beat join one
  /// by one between [_beatNotesFrom] and [_beatNotesTo], then the notes
  /// between beats between [_offbeatNotesFrom] and [_offbeatNotesTo]. So the
  /// song fills in gradually instead of doubling all at once.
  static final _noteJoinsAt = <MelodyPhrase, Map<MelodyNote, double>>{};

  static Map<MelodyNote, double> _joinsFor(MelodyPhrase phrase) {
    final joins = <MelodyNote, double>{};
    for (final (tier, from, to) in [
      (1, _beatNotesFrom, _beatNotesTo),
      (2, _offbeatNotesFrom, _offbeatNotesTo),
    ]) {
      final notes = phrase.notes.where((n) => n.tier == tier).toList()
        // A fixed shuffle, so they join spread over the song, not bar by bar
        ..shuffle(Random(tier));
      for (var i = 0; i < notes.length; i++) {
        joins[notes[i]] = from + (to - from) * (i + 0.5) / notes.length;
      }
    }
    return joins;
  }

  static const _beatNotesFrom = 0.12;
  static const _beatNotesTo = 0.45;
  static const _offbeatNotesFrom = 0.5;
  static const _offbeatNotesTo = 0.85;

  bool _notePlays(MelodyPhrase phrase, MelodyNote note, SongSection section) {
    if (note.tier == 0 || _song.fullMelody) {
      return true;
    }
    if (section.notesAhead < 0) {
      return false;
    }
    final joinsAt =
        _noteJoinsAt.putIfAbsent(phrase, () => _joinsFor(phrase))[note] ?? 0;
    return _difficulty + section.notesAhead >= joinsAt;
  }

  /// Past this difficulty more notes come on their own, so only the first
  /// beat of each bar keeps its pair orb, and the harmony orbs stop
  static const _companionsFadeFrom = 0.45;

  /// The orbs that come with [note]: a pair of the other kind from the
  /// opposite side half a beat later, and at the chord changes of the
  /// chorus a harmony orb next to it. Together they play a little riff.
  ({bool pair, bool harmony}) _companionsOf(
    MelodyPhrase phrase,
    MelodyNote note,
    SongSection section,
  ) {
    if (_song.fullMelody) {
      // The tune plays as written, with nothing added
      return (pair: false, harmony: false);
    }
    final calm = _difficulty < _companionsFadeFrom;
    final onPairBeat =
        note.beat == 0 || (calm && section.midBarPairs && note.beat == 2);
    // The pair takes the half beat after its note, so it never sounds at
    // the same time as a note of the other kind. If the melody has a note
    // there, the pair stays out.
    final slotTaken = phrase.notes.any(
      (n) => n.bar == note.bar && n.beat == note.beat + 0.5,
    );
    return (
      pair: section.pairs && onPairBeat && !slotTaken,
      harmony: calm && section.triads && note.beat == 0 && note.bar % 4 == 0,
    );
  }

  /// Picks where an orb comes from: fire orbs in one group, ice orbs in
  /// one group on the opposite side, see [OrbSides]
  double _pickAngle(OrbType type, double land) =>
      _sides.angleFor(type, land, _difficulty, overdrive: _overdrive);

  /// Plans an orb, returns where it comes from (null if it was skipped)
  double? _add(
    double land,
    OrbType type,
    double speed, {
    RhythmHit? hit,
    double? angle,
  }) {
    final radius = _spawnRadius;
    final launchAt = land - _flightTime(speed, radius) - _mountDelay;
    if (launchAt < _songTime - _maxLate) {
      // Too close to fly in from behind the ring (the first beats of a run
      // at slow speeds). Skip it before its rift opens, or the rift would
      // flash open and shut right away.
      return null;
    }
    angle ??= _pickAngle(type, land);
    final formDuration = RingRift.formDurationFor(
      _difficulty,
      overdrive: _overdrive,
    );
    _planned.add(
      _PlannedOrb(
        land: land,
        launchAt: launchAt,
        throughAt: launchAt + _hiddenRun / speed,
        portalAt: launchAt + _hiddenRun / speed - formDuration,
        type: type,
        angle: angle,
        radius: radius,
        speed: speed,
        hit: hit,
      ),
    );
    _planned.sort((a, b) => a.launchAt.compareTo(b.launchAt));
    return angle;
  }

  // ---- the song ----

  int _barOf(int beat) => (beat / _song.beatsPerBar).floor();

  /// The song stage of each pass of the backing loop. It is picked when the
  /// first beat of that pass is planned, so a pass never changes phrase or
  /// layers halfway, even if the difficulty crosses into the next stage.
  final _stageOfLoop = <int, SongStage>{};

  SongSection _sectionFor(int loop) => _song.sectionFor(loop);

  SongStage _stageFor(int loop) => _stageOfLoop.putIfAbsent(
    loop,
    () => _song.stageFor(loop: loop, difficulty: _difficulty),
  );

  MelodyPhrase _phraseFor(int loop) {
    final phrases = _stageFor(loop).phrases;
    return phrases[loop % phrases.length];
  }

  void _planMelodyBeat(int beat, double speed) {
    final bar = _barOf(beat);
    final beatInBar = beat % _song.beatsPerBar;
    final loop = (bar / _song.bars).floor();
    final phrase = _phraseFor(loop);
    final section = _sectionFor(loop);
    for (final note in phrase.notes) {
      if (note.bar != bar % _song.bars) {
        continue;
      }
      if (note.beat.floor() != beatInBar) {
        continue;
      }
      if (!_song.notePlaysIn(loop, note) ||
          !_notePlays(phrase, note, section)) {
        continue;
      }
      final land =
          _beatTime(beat) + (note.beat - beatInBar) * _song.beatSeconds;
      final ice = phrase.isIce(note);
      final type = ice ? OrbType.ice : OrbType.fire;
      final timbre = ice ? 'ice' : 'fire';
      // Fire notes sound an octave down
      final octave = ice ? 0 : -12;
      final angle = _add(
        land,
        type,
        speed,
        hit: RhythmHit(timbre: timbre, midi: note.midi + octave, land: land),
      );
      if (angle == null) {
        continue;
      }
      final companions = _companionsOf(phrase, note, section);
      if (companions.harmony) {
        _add(
          land,
          type,
          speed,
          angle: _sides.harmonyAngleFor(
            type,
            angle,
            land,
            _difficulty,
            overdrive: _overdrive,
          ),
          hit: RhythmHit(
            timbre: timbre,
            midi: _song.harmonyBelow(note.midi, bar) + octave,
            land: land,
            volume: 0.55,
            companion: true,
          ),
        );
      }
      if (companions.pair) {
        // From right behind the melody orb, so the shield doesn't have to
        // move: its other end points at it. It lands half a beat later, so
        // the two notes sound one after the other.
        final pairLand = land + _song.beatSeconds / 2;
        final jitter = (_pairRandom.nextDouble() * 2 - 1) * _pairJitter;
        _add(
          pairLand,
          ice ? OrbType.fire : OrbType.ice,
          speed,
          angle: angle + pi + jitter,
          hit: RhythmHit(
            timbre: ice ? 'fire' : 'ice',
            // The chord's root: up high on a bell, or low on a fire pair
            midi: ice ? _song.rootFrom(46, bar) : _song.rootFrom(74, bar),
            land: pairLand,
            volume: 0.6,
            companion: true,
          ),
        );
      }
    }
  }

  final _pairRandom = Random();
  static const _pairJitter = 6 * pi / 180;

  // ---- backing layers ----

  int _layersLoop = -1;

  /// At the start of each pass of the loop, fades the extra backing layers
  /// in or out to match the stage of the phrase that pass plays
  void _updateLayers() {
    final loop = (_songTime / _song.loopSeconds).floor();
    if (loop == _layersLoop || loop < 0) {
      // The intro keeps the fade in it started with
      return;
    }
    final stage = _stageOfLoop[loop];
    if (stage == null) {
      return;
    }
    _layersLoop = loop;
    _stageOfLoop.removeWhere((l, _) => l < loop);
    final section = _sectionFor(loop);
    _audio.setMusicLayers(
      section.layersOver(stage.layers),
      muted: section.mutedStemsOf(_song),
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
    _audio.playNote(hit.timbre, hit.midi, pan: pan, volume: hit.volume);
    parent.player.onNotePlayed(hit);
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
