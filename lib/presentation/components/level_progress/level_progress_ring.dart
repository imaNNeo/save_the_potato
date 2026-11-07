import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Matrix4;
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_director.dart';
import 'package:save_the_potato/presentation/rhythm/rhythm_songs.dart';
import 'package:save_the_potato/service_locator.dart';

/// How the level's progress is drawn on the arena ring. Samples to pick
/// from; the web preview switches them with `?ring=comet|beads|wave`.
enum ProgressRingStyle {
  /// A comet runs around the ring and leaves a glowing trail
  comet,

  /// One bead per bar of the song lights up around the ring
  beads,

  /// The played part of the ring is an equalizer dancing to the beat
  wave;

  static final ProgressRingStyle current = () {
    if (!kIsWeb) {
      return ProgressRingStyle.comet;
    }
    final name = Uri.base.queryParameters['ring'];
    return ProgressRingStyle.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ProgressRingStyle.comet,
    );
  }();
}

const _fire = Color(0xFFFF8A3D);
const _ice = Color(0xFF7FD4FF);
const _gold = Color(0xFFFFD36B);
const _white = Color(0xFFFFFFFF);

/// A rotation around the screen, for gradient matrices
Float64List _rotZ(double a) => Float64List.fromList([
  cos(a), sin(a), 0, 0, //
  -sin(a), cos(a), 0, 0, //
  0, 0, 1, 0, //
  0, 0, 0, 1,
]);

double _clamp01(double x) => x.clamp(0.0, 1.0);

double _fract(double x) => x - x.floorToDouble();

/// 0 before [from], 1 a bit after it: the features of a stage fade in
double _ramp(double p, double from, [double width = 0.06]) =>
    _clamp01((p - from) / width);

double _hash(int a, int b) {
  var h = a * 374761393 + b * 668265263;
  h = (h ^ (h >> 13)) * 1274126177;
  return ((h ^ (h >> 16)) & 0xFFFF) / 0xFFFF;
}

Offset _polar(double angle, double radius) =>
    Offset(cos(angle), sin(angle)) * radius;

class _Spark {
  _Spark({
    required this.p,
    required this.v,
    required this.life,
    required this.color,
    required this.size,
    this.drag = 2.2,
  }) : maxLife = life;

  Offset p;
  Offset v;
  double life;
  final double maxLife;
  final Color color;
  final double size;
  final double drag;
}

/// A ring wave: grows (or shrinks) from [from] to [to] and fades out
class _Wave {
  _Wave({
    required this.from,
    required this.to,
    required this.duration,
    required this.color,
    this.width = 3,
    this.center = Offset.zero,
  });

  final double from;
  final double to;
  final double duration;
  final Color color;
  final double width;
  final Offset center;
  double t = 0;
}

/// Thin quads from a radius to another, each with its own color, drawn
/// together as one triangle mesh
class _SpikeMesh {
  final _xy = <double>[];
  final _colors = <int>[];

  void add(
    double angle,
    double from,
    double to,
    double width,
    Color color,
    double alpha,
  ) {
    final c = cos(angle);
    final s = sin(angle);
    final nx = -s * width / 2;
    final ny = c * width / 2;
    final bx = c * from;
    final by = s * from;
    final tx = c * to;
    final ty = s * to;
    // Two triangles: base-left, base-right, tip-right / base-left,
    // tip-right, tip-left. The tip is a bit dimmer.
    _xy.addAll([
      bx - nx, by - ny, bx + nx, by + ny, tx + nx, ty + ny, //
      bx - nx, by - ny, tx + nx, ty + ny, tx - nx, ty - ny,
    ]);
    final base = color.withValues(alpha: _clamp01(alpha)).toARGB32();
    final tip = color.withValues(alpha: _clamp01(alpha * 0.6)).toARGB32();
    _colors.addAll([base, base, tip, base, tip, tip]);
  }

  void draw(Canvas canvas, Paint paint) {
    if (_xy.isEmpty) {
      return;
    }
    canvas.drawVertices(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.fromList(_xy),
        colors: Int32List.fromList(_colors),
      ),
      BlendMode.dst,
      paint..color = _white,
    );
  }
}

/// Colored triangles, drawn together in one call
class _ColorMesh {
  final _xy = <double>[];
  final _colors = <int>[];

  /// A quad from four corners in order, each with its color
  void quad(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    double x4,
    double y4,
    int c1,
    int c2,
    int c3,
    int c4,
  ) {
    _xy.addAll([x1, y1, x2, y2, x3, y3, x1, y1, x3, y3, x4, y4]);
    _colors.addAll([c1, c2, c3, c1, c3, c4]);
  }

  void flush(Canvas canvas, Paint paint) {
    if (_xy.isEmpty) {
      return;
    }
    canvas.drawVertices(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.fromList(_xy),
        colors: Int32List.fromList(_colors),
      ),
      BlendMode.dst,
      paint..color = _white,
    );
    _xy.clear();
    _colors.clear();
  }
}

/// Glows and dots stamped from one small picture, all in one draw call.
/// A radial gradient or a circle per dot is a draw call each, and the
/// glows made phones lag.
class _SpriteBatch {
  static const _glowRadius = 32.0;
  static const _dotRadius = 7.0;
  static const _glowRect = [0.0, 0.0, 64.0, 64.0];
  static const _dotRect = [64.0, 0.0, 80.0, 16.0];

  static final ui.Image atlas = () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(_glowRadius, _glowRadius);
    canvas
      ..drawCircle(
        c,
        _glowRadius,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            _glowRadius,
            const [Color(0xFFFFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)],
            const [0, 0.35, 1],
          ),
      )
      ..drawCircle(
        const Offset(72, 8),
        _dotRadius,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    return recorder.endRecording().toImageSync(80, 64);
  }();

  final _transforms = <double>[];
  final _rects = <double>[];
  final _colors = <int>[];

  void _add(
    Offset p,
    double scale,
    double anchor,
    List<double> rect,
    Color color,
    double alpha,
  ) {
    if (scale <= 0 || alpha <= 0) {
      return;
    }
    _transforms.addAll([
      scale,
      0,
      p.dx - scale * anchor,
      p.dy - scale * anchor,
    ]);
    _rects.addAll(rect);
    _colors.add(color.withValues(alpha: _clamp01(alpha)).toARGB32());
  }

  void glow(Offset p, double r, Color color, double alpha) =>
      _add(p, r / _glowRadius, _glowRadius, _glowRect, color, alpha);

  void dot(Offset p, double r, Color color, double alpha) =>
      _add(p, r / _dotRadius, 8, _dotRect, color, alpha);

  void flush(Canvas canvas, Paint paint) {
    if (_colors.isEmpty) {
      return;
    }
    canvas.drawRawAtlas(
      atlas,
      Float32List.fromList(_transforms),
      Float32List.fromList(_rects),
      Int32List.fromList(_colors),
      BlendMode.modulate,
      null,
      paint
        ..shader = null
        ..color = _white
        ..filterQuality = FilterQuality.low,
    );
    _transforms.clear();
    _rects.clear();
    _colors.clear();
  }
}

class _Note {
  _Note(this.at, this.timbre, this.midi, this.volume);

  final double at;
  final String timbre;
  final int midi;
  final double volume;
}

/// Shows how far the level's song is on the arena ring, where the orbs
/// come in: it starts at the top, and a full round is the end of the
/// level. It starts plain and gets juicier at each quarter, and closing the
/// ring sets off a big celebration.
class LevelProgressRing extends PositionComponent
    with
        HasGameReference<PotatoGame>,
        FlameBlocListenable<GameCubit, GameState> {
  LevelProgressRing({required this.director, ProgressRingStyle? style})
    : style = style ?? ProgressRingStyle.current,
      super(priority: -1);

  /// Draws each kind of shader the ring uses once, for [GameShaderWarmUp]
  /// (it clips everything to one pixel at the origin), so none of them
  /// compiles mid-level when a quarter or the finale brings it in
  static void warmUp(Canvas canvas) {
    final stroke = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = _white;
    const rect = Rect.fromLTWH(-3, -3, 6, 6);
    canvas
      ..drawArc(rect, 0, 2, false, stroke)
      ..drawCircle(Offset.zero, 2, stroke)
      ..drawLine(const Offset(-3, 0), const Offset(3, 0), stroke)
      ..drawPath(
        Path()
          ..moveTo(-3, 0)
          ..lineTo(0, 1)
          ..lineTo(3, 0),
        stroke,
      )
      ..drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList([0, 0, 1, 1]),
        stroke,
      )
      ..drawRawPoints(
        ui.PointMode.lines,
        Float32List.fromList([-3, 0, 3, 1]),
        stroke,
      )
      ..drawCircle(Offset.zero, 2, Paint()..blendMode = BlendMode.plus);
    (_SpikeMesh()..add(0, -3, 3, 2, _white, 0.5)).draw(
      canvas,
      Paint()..blendMode = BlendMode.plus,
    );
    (_ColorMesh()..quad(-3, -1, 3, -1, 3, 1, -3, 1, -1, -1, -1, -1)).flush(
      canvas,
      Paint()..blendMode = BlendMode.plus,
    );
    (_SpriteBatch()
          ..glow(Offset.zero, 3, _white, 1)
          ..dot(Offset.zero, 2, _white, 1))
        .flush(canvas, Paint()..blendMode = BlendMode.plus);
    for (final stops in const [
      [0.0, 0.7, 1.0],
      [0.0, 0.25, 0.5, 0.75, 1.0],
    ]) {
      final sweep = Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..shader = ui.Gradient.sweep(
          Offset.zero,
          [for (var i = 0; i < stops.length; i++) _white],
          stops,
          TileMode.clamp,
          0,
          2 * pi,
          _rotZ(1),
        );
      canvas
        ..drawArc(rect, 0, 2, false, sweep)
        ..drawCircle(Offset.zero, 2, sweep);
    }
    canvas.drawLine(
      const Offset(-3, 0),
      const Offset(3, 0),
      Paint()
        ..blendMode = BlendMode.plus
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..shader = ui.Gradient.linear(const Offset(-3, 0), const Offset(3, 0), [
          _white,
          const Color(0x00FFFFFF),
        ]),
    );
    canvas.drawCircle(
      Offset.zero,
      3,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          Offset.zero,
          3,
          [_white, const Color(0x40FFFFFF), const Color(0x00FFFFFF)],
          [0, 0.35, 1],
        ),
    );
  }

  final RhythmDirector director;
  final ProgressRingStyle style;
  final _audio = getIt.get<AudioHelper>();

  static const double radius = ArenaRing.radius;
  static const _start = -pi / 2;

  final _rnd = Random(7);
  final _sparks = <_Spark>[];
  final _waves = <_Wave>[];
  final _notes = <_Note>[];

  /// Moving bright bits along the played arc, by their age
  final _ripples = <double>[];

  Song _song = RhythmSongs.song;
  double _time = 0;
  double _visible = 0;

  /// 0 to 1 through the song
  double _progress = 0;

  /// In beats from the start of the song
  double _beat = 0;
  int _lastBeat = -1;

  /// How many quarters are passed (0 to 3), and how long ago the last was
  int _milestones = 0;
  double _milestoneAge = 9;

  /// Seconds since the ring closed, null before
  double? _finale;

  /// When each bead (bar) lit up, for the beads' pop
  final _litAt = <int, double>{};

  Color get _accent => Color(_song.colors.first);

  Color get _mid => Color(_song.colors[1]);

  int get _root => _song.chords.first.first;

  int get _bars => (_song.totalBeats ?? 0) ~/ 4;

  double get _kick => pow(1 - _fract(_beat), 3).toDouble();

  double get _sixteenth => pow(1 - _fract(_beat * 4), 4).toDouble();

  @override
  bool listenWhen(GameState previousState, GameState newState) =>
      previousState.playingState != newState.playingState ||
      previousState.level != newState.level;

  @override
  void onNewState(GameState state) {
    super.onNewState(state);
    if (state.playingState.isGuide || state.playingState.isNone) {
      _reset(state);
    }
  }

  void _reset(GameState state) {
    _song = state.song;
    _progress = 0;
    _beat = 0;
    _lastBeat = -1;
    _milestones = 0;
    _milestoneAge = 9;
    _finale = null;
    _sparks.clear();
    _waves.clear();
    _notes.clear();
    _ripples.clear();
    _litAt.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final state = bloc.state;
    if (state.playingState.isPaused) {
      return;
    }
    _time += dt;
    _song = state.song;
    final playing = state.playingState.isPlaying && !state.tutorial;
    final cleared = state.playingState.isLevelCleared;
    final target = !state.isLevelsMode
        ? 0.0
        : playing || cleared || _finale != null
        ? 1.0
        : state.playingState.isGameOver
        ? 0.25
        : 0.0;
    _visible += (target - _visible) * min(1, dt * 3);

    final duration = _song.durationSeconds;
    if (duration != null && playing && director.isRunning) {
      final songTime = director.songTime;
      _beat = songTime / _song.beatSeconds;
      _progress = _clamp01(songTime / duration);
    } else if (_finale != null) {
      // The music goes on a bit after the end: keep the beat going
      _beat += dt / _song.beatSeconds;
    }

    if (state.isLevelsMode && (playing || cleared)) {
      final beat = _beat.floor();
      if (beat != _lastBeat) {
        if (_lastBeat >= 0 && _finale == null) {
          _onBeat(beat);
        }
        _lastBeat = beat;
      }
      final quarter = min(3, (_progress * 4).floor());
      while (_milestones < quarter) {
        _milestones++;
        _onMilestone(_milestones);
      }
      if (_progress >= 1 && _finale == null) {
        _startFinale();
      }
    }

    _milestoneAge += dt;
    if (_finale != null) {
      _finale = _finale! + dt;
      _updateFinale(_finale! - dt, _finale!);
    }
    _updateSparks(dt);
    for (final w in _waves) {
      w.t += dt;
    }
    _waves.removeWhere((w) => w.t >= w.duration);
    for (var i = 0; i < _ripples.length; i++) {
      _ripples[i] += dt;
    }
    _ripples.removeWhere((r) => r > 1.6);
    _playNotes();
  }

  // ------------------------------------------------------------------
  // Events

  double get _headAngle => _start + _progress * 2 * pi;

  Offset get _head => _polar(_headAngle, radius);

  void _onBeat(int beat) {
    final p = _progress;
    final downbeat = beat % 4 == 0;
    switch (style) {
      case ProgressRingStyle.comet:
        if (p >= 0.25) {
          _emitFromHead(2 + _milestones * 2, speed: 60 + 40.0 * _milestones);
        }
        if (p >= 0.5 && downbeat) {
          _ripples.add(0);
        }
      case ProgressRingStyle.beads:
        if (downbeat) {
          final bar = beat ~/ 4 - 1;
          if (bar >= 0) {
            _litAt[bar] = _time;
            if (p >= 0.25) {
              _burst(
                _polar(_beadAngle(bar), radius),
                4 + _milestones * 2,
                speed: 70,
                colors: [_accent, _white],
              );
            }
          }
        }
      case ProgressRingStyle.wave:
        if (p >= 0.75) {
          for (var i = 0; i < 3; i++) {
            final a = _start + _rnd.nextDouble() * p * 2 * pi;
            _burst(
              _polar(a, radius + 18),
              2,
              speed: 90,
              colors: [_waveColor(a - _start, p), _white],
              outward: a,
            );
          }
        }
    }
  }

  void _onMilestone(int index) {
    _milestoneAge = 0;
    final head = _head;
    _waves.add(
      _Wave(
        from: 4,
        to: 60 + 20.0 * index,
        duration: 0.6,
        color: _white,
        width: 3,
        center: head,
      ),
    );
    _waves.add(
      _Wave(
        from: radius,
        to: radius + 26,
        duration: 0.7,
        color: _accent,
        width: 2,
      ),
    );
    _burst(head, 18 + index * 8, speed: 160, colors: [_accent, _white, _gold]);
    // A short rising chime, higher at each quarter
    const steps = [0, 4, 7, 12];
    for (var i = 0; i < index + 1; i++) {
      _scheduleNote(
        i * 0.07,
        i.isEven ? 'ice' : 'fire',
        72 + _root + steps[i % 4] + (index - 1) * 2,
        0.55,
      );
    }
  }

  void _startFinale() {
    _finale = 0;
    _progress = 1;
    // A big rising arpeggio, fire and ice taking turns
    const steps = [0, 4, 7, 12, 16, 19, 24, 28];
    for (var i = 0; i < steps.length; i++) {
      _scheduleNote(
        0.06 * i,
        i.isEven ? 'ice' : 'fire',
        67 + _root + steps[i],
        0.75,
      );
    }
    // And a final chord when the sparks blow
    for (final s in const [12, 16, 19, 24]) {
      _scheduleNote(_blowAt, 'ice', 67 + _root + s, 0.6);
    }
  }

  /// When the finale blows up, after the ring closed
  double get _blowAt => switch (style) {
    ProgressRingStyle.comet => 0.0,
    ProgressRingStyle.beads => 1.25,
    ProgressRingStyle.wave => 0.85,
  };

  void _updateFinale(double before, double now) {
    bool passed(double at) => before < at && now >= at;
    if (passed(0.0001) || (before == 0 && now > 0)) {
      if (style == ProgressRingStyle.comet) {
        _cometBlow();
      } else {
        _waves.add(
          _Wave(
            from: radius,
            to: radius + 40,
            duration: 0.5,
            color: _white,
            width: 6,
          ),
        );
      }
    }
    if (style != ProgressRingStyle.comet && passed(_blowAt)) {
      style == ProgressRingStyle.beads ? _beadsBlow() : _waveBlow();
    }
    if (passed(_blowAt + 0.45)) {
      game.world.player.face.amazed();
    }
    // Afterglow fireworks
    for (final at in const [0.55, 0.9, 1.25, 1.6]) {
      if (passed(_blowAt + at)) {
        final a = _rnd.nextDouble() * 2 * pi;
        final p = _polar(a, radius * (0.55 + _rnd.nextDouble() * 0.35));
        _burst(
          p,
          60,
          speed: 260,
          colors: [_accent, _gold, _white, _fire, _ice],
          size: 3.5,
        );
        _waves.add(
          _Wave(
            from: 2,
            to: 70,
            duration: 0.5,
            color: _accent,
            width: 2,
            center: p,
          ),
        );
        _scheduleNote(0, 'fire', 79 + _root + (at * 10).round() % 12, 0.45);
      }
    }
  }

  void _shake(double amount) {
    game.camera.viewfinder.add(
      MoveEffect.by(
        Vector2(amount, amount),
        NoiseEffectController(
          duration: 0.6,
          noise: PerlinNoise(frequency: 300),
        ),
      ),
    );
    game.camera.viewfinder.add(
      ScaleEffect.by(
        Vector2.all(1.06),
        EffectController(duration: 0.12, reverseDuration: 0.5),
      ),
    );
  }

  void _cometBlow() {
    _shake(10);
    _ringBurst(170);
    _waves
      ..add(
        _Wave(
          from: radius,
          to: radius + 14,
          duration: 0.9,
          color: _white,
          width: 14,
        ),
      )
      ..add(
        _Wave(from: radius, to: 60, duration: 0.45, color: _accent, width: 5),
      );
  }

  void _beadsBlow() {
    _shake(8);
    for (var bar = 0; bar < _bars; bar++) {
      final a = _beadAngle(bar);
      final big = bar % Song.bars == 0;
      for (var i = 0; i < (big ? 5 : 2); i++) {
        final spread = (_rnd.nextDouble() - 0.5) * 0.5;
        final speed = 160 + _rnd.nextDouble() * 260;
        _sparks.add(
          _Spark(
            p: _polar(a, radius),
            v: _polar(a + spread, speed * (_rnd.nextBool() ? 1 : -0.6)),
            life: 1.2 + _rnd.nextDouble() * 0.8,
            color: _beadColor(bar, 1),
            size: big ? 5 : 3.2,
            drag: 1.6,
          ),
        );
      }
    }
    _waves.add(
      _Wave(from: 0, to: radius, duration: 0.8, color: _gold, width: 10),
    );
  }

  void _waveBlow() {
    _shake(12);
    _ringBurst(120, from: 70);
    _waves
      ..add(
        _Wave(from: 70, to: radius, duration: 0.7, color: _white, width: 10),
      )
      ..add(_Wave(from: 70, to: radius, duration: 0.6, color: _gold, width: 4));
  }

  /// Sparks all around a ring of [from], flying in and out
  void _ringBurst(int count, {double from = radius}) {
    final colors = [_accent, _gold, _white, _fire, _ice];
    for (var i = 0; i < count; i++) {
      final a = _rnd.nextDouble() * 2 * pi;
      final out = _rnd.nextDouble() < 0.7;
      final speed = (out ? 140 : 80) + _rnd.nextDouble() * 280;
      _sparks.add(
        _Spark(
          p: _polar(a, from),
          v: _polar(a, out ? speed : -speed),
          life: 0.9 + _rnd.nextDouble() * 0.9,
          color: colors[i % colors.length],
          size: 3 + _rnd.nextDouble() * 4,
          drag: 1.8,
        ),
      );
    }
  }

  void _emitFromHead(int count, {required double speed}) {
    final a = _headAngle;
    // Backwards along the ring, and a bit in or out
    final back = a - pi / 2;
    for (var i = 0; i < count; i++) {
      final dir = back + (_rnd.nextDouble() - 0.5) * 1.6;
      _sparks.add(
        _Spark(
          p: _head,
          v: _polar(dir, speed * (0.5 + _rnd.nextDouble())),
          life: 0.4 + _rnd.nextDouble() * 0.5,
          color: _milestones >= 3
              ? (i.isEven ? _fire : _ice)
              : (i.isEven ? _accent : _white),
          size: 1.8 + _milestones * 0.5,
        ),
      );
    }
  }

  void _burst(
    Offset at,
    int count, {
    required double speed,
    required List<Color> colors,
    double? outward,
    double size = 1.8,
  }) {
    for (var i = 0; i < count; i++) {
      final dir = outward != null
          ? outward + (_rnd.nextDouble() - 0.5) * 0.9
          : _rnd.nextDouble() * 2 * pi;
      _sparks.add(
        _Spark(
          p: at,
          v: _polar(dir, speed * (0.3 + _rnd.nextDouble())),
          life: 0.5 + _rnd.nextDouble() * 0.5,
          color: colors[i % colors.length],
          size: size + _rnd.nextDouble() * 2,
        ),
      );
    }
  }

  void _updateSparks(double dt) {
    for (final s in _sparks) {
      s.life -= dt;
      s.p += s.v * dt;
      s.v *= exp(-s.drag * dt);
    }
    _sparks.removeWhere((s) => s.life <= 0);
    if (_sparks.length > 400) {
      _sparks.removeRange(0, _sparks.length - 400);
    }
  }

  void _scheduleNote(double after, String timbre, int midi, double volume) {
    _notes.add(_Note(_time + after, timbre, midi, volume));
  }

  void _playNotes() {
    if (_notes.isEmpty) {
      return;
    }
    final due = _notes.where((n) => n.at <= _time).toList();
    for (final n in due) {
      _audio.playNote(n.timbre, n.midi, volume: n.volume);
    }
    _notes.removeWhere(due.contains);
  }

  // ------------------------------------------------------------------
  // Drawing

  /// Preview only: `?ring=off` hides it, to measure what it costs
  static final _off = kIsWeb && Uri.base.queryParameters['ring'] == 'off';

  /// Preview only: `?perf=1` prints how long drawing it takes
  static final _perf = kIsWeb && Uri.base.queryParameters['perf'] == '1';
  final _watch = Stopwatch();
  int _perfFrames = 0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_visible < 0.01 || _off) {
      return;
    }
    if (_perf) {
      _watch.start();
      _render(canvas);
      _watch.stop();
      if (++_perfFrames % 120 == 0) {
        debugPrint(
          'ring ${style.name} ${(_progress * 100).round()}%: '
          '${(_watch.elapsedMicroseconds / 120).round()}us/frame, '
          '${_sparks.length} sparks',
        );
        _watch.reset();
      }
      return;
    }
    _render(canvas);
  }

  void _render(Canvas canvas) {
    switch (style) {
      case ProgressRingStyle.comet:
        _renderComet(canvas);
      case ProgressRingStyle.beads:
        _renderBeads(canvas);
      case ProgressRingStyle.wave:
        _renderWave(canvas);
    }
    _renderStartMark(canvas);
    _renderWaves(canvas);
    _renderSparks(canvas);
    _bands.flush(canvas, _fillPaint);
    _sprites.flush(canvas, _bloomPaint);
  }

  // One paint of each kind, reused for every draw, so a frame doesn't
  // make hundreds of objects for the garbage collector
  final _strokePaint = Paint()
    ..blendMode = BlendMode.plus
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final _fillPaint = Paint()..blendMode = BlendMode.plus;
  final _bloomPaint = Paint()..blendMode = BlendMode.plus;

  /// Every glow and dot of a frame, drawn together in one call at the end
  final _sprites = _SpriteBatch();

  /// Every band along the ring (trails, echoes, the finale ring) of a
  /// frame, drawn together as one triangle mesh. Stroking long paths is
  /// slow on phones, colored triangles are not.
  final _bands = _ColorMesh();

  Paint _stroke(Color color, double width, double alpha) => _strokePaint
    ..strokeWidth = width
    ..color = color.withValues(alpha: _clamp01(alpha * _visible));

  /// A round dot, batched
  void _dot(Offset p, double r, Color color, double alpha) =>
      _sprites.dot(p, r, color, _clamp01(alpha * _visible));

  /// Round dots from a flat x, y list, batched
  void _dots(
    Canvas canvas,
    List<double> xy,
    double size,
    Color color,
    double alpha,
  ) {
    for (var i = 0; i + 1 < xy.length; i += 2) {
      _dot(Offset(xy[i], xy[i + 1]), size, color, alpha);
    }
  }

  /// A soft glow, batched
  void _bloom(Canvas canvas, Offset p, double r, Color color, double a) {
    if (r <= 0 || a <= 0) {
      return;
    }
    _sprites.glow(p, r, color, _clamp01(a * _visible));
  }

  /// A band along the ring from [from] for [sweep] radians, [width] wide,
  /// at the radius [radiusAt] gives for each angle along it, colored by
  /// [colorAt] (0 at the start, 1 at the end)
  void _band(
    double from,
    double sweep,
    double width, {
    double Function(double along)? radiusAt,
    Color? color,
    Color Function(double t)? colorAt,
    double alpha = 1,
    double step = 0.05,
  }) {
    if (sweep <= 0 || width <= 0 || alpha <= 0) {
      return;
    }
    final n = max(1, (sweep / step).ceil());
    // One color for the whole band: work it out once
    final fixed = color
        ?.withValues(alpha: _clamp01(color.a * alpha * _visible))
        .toARGB32();
    double? px, py, pnx, pny;
    int? pc;
    for (var i = 0; i <= n; i++) {
      final along = sweep * i / n;
      final a = from + along;
      final r = radiusAt?.call(along) ?? radius;
      final c = cos(a);
      final s = sin(a);
      final x = c * r;
      final y = s * r;
      // Normal of the ring, half the width
      final nx = c * width / 2;
      final ny = s * width / 2;
      final int argb;
      if (colorAt == null) {
        argb = fixed!;
      } else {
        final c = colorAt(i / n);
        argb = c.withValues(alpha: _clamp01(c.a * alpha * _visible)).toARGB32();
      }
      if (px != null) {
        _bands.quad(
          px - pnx!,
          py! - pny!,
          px + pnx,
          py + pny,
          x + nx,
          y + ny,
          x - nx,
          y - ny,
          pc!,
          pc,
          argb,
          argb,
        );
      }
      px = x;
      py = y;
      pnx = nx;
      pny = ny;
      pc = argb;
    }
  }

  /// A small notch at the top: where the ring starts and has to come back
  void _renderStartMark(Canvas canvas) {
    final top = _polar(_start, radius);
    final pulse = _finale == null ? 0.6 + 0.4 * _kick : 0.0;
    canvas.drawLine(
      top + const Offset(0, -9),
      top + const Offset(0, 9),
      _stroke(_white, 2, 0.5 * pulse + 0.15),
    );
  }

  void _renderWaves(Canvas canvas) {
    for (final w in _waves) {
      final k = _clamp01(w.t / w.duration);
      final e = 1 - pow(1 - k, 3).toDouble();
      final r = w.from + (w.to - w.from) * e;
      canvas.drawCircle(
        w.center,
        max(0.0, r),
        _stroke(w.color, w.width * (1 - k * 0.6), (1 - k) * 0.9),
      );
    }
  }

  void _renderSparks(Canvas canvas) {
    for (final s in _sparks) {
      final k = _clamp01(s.life / s.maxLife);
      _dot(s.p, s.size * (0.4 + 0.6 * k), s.color, k);
    }
  }

  /// How much brighter everything is just after a quarter is passed
  double get _milestoneFlash => exp(-_milestoneAge * 4);

  // ---- comet ----

  void _renderComet(Canvas canvas) {
    final p = _progress;
    final f = _finale;
    final sweep = p * 2 * pi;
    final s1 = _ramp(p, 0.25);
    final s2 = _ramp(p, 0.5);
    final s3 = _ramp(p, 0.75);
    final kick = _kick * s1;
    final flash = _milestoneFlash;

    if (f != null) {
      _renderCometFinale(canvas, f);
      return;
    }

    // The trail: a plain line first, then brighter, wider and colorful
    final width = 2.0 + 1.5 * s1 + 1.5 * s2 + 2 * s3 + kick * (1 + 2 * s2);
    final hot = Color.lerp(_accent, _white, 0.6)!;
    final plain = _accent.withValues(alpha: 0.75 + 0.25 * flash);
    _band(
      _start,
      sweep,
      width,
      colorAt: s2 <= 0
          ? (_) => plain
          : (t) => t < 0.7
                ? Color.lerp(
                    _mid.withValues(alpha: 0.7),
                    _accent.withValues(alpha: 0.9),
                    t / 0.7,
                  )!
                : Color.lerp(
                    _accent.withValues(alpha: 0.9),
                    hot,
                    (t - 0.7) / 0.3,
                  )!,
    );
    // A soft glow under it
    _band(
      _start,
      sweep,
      width * 3.5,
      color: _accent,
      alpha: 0.08 + 0.1 * kick + 0.25 * flash,
    );

    // Half way: a wobbly echo just inside
    if (s2 > 0) {
      _band(
        _start,
        sweep,
        1.2,
        radiusAt: (a) => radius - 9 + sin(a * 14 - _time * 5) * (2 + 3 * kick),
        color: _white,
        alpha: 0.35 * s2,
        step: 0.035,
      );
    }

    // Last quarter: fire and ice twist around the trail
    if (s3 > 0) {
      for (final side in const [1.0, -1.0]) {
        _band(
          _start,
          sweep,
          1.6,
          radiusAt: (a) =>
              radius + side * sin(a * 22 - _time * 7) * (5 + 3 * kick),
          color: side > 0 ? _fire : _ice,
          alpha: 0.7 * s3,
          step: 0.03,
        );
      }
      // And it sheds sparks all the time
      if (_rnd.nextDouble() < 0.5) {
        _emitFromHead(1, speed: 80);
      }
    }

    // Bright bits running back along the trail on each bar
    for (final age in _ripples) {
      final a = sweep - age * 2.4;
      if (a <= 0) {
        continue;
      }
      _band(
        _start + max(0.0, a - 0.18),
        min(0.18, a),
        width + 2,
        color: _white,
        alpha: 0.8 * (1 - age / 1.6),
      );
    }

    // Quarter marks: dim before, lit after
    for (var q = 1; q < 4; q++) {
      final at = _polar(_start + q * pi / 2, radius);
      final lit = p >= q / 4;
      _dot(
        at,
        lit ? 4.5 + 1.5 * _kick : 3,
        lit ? _gold : _white,
        lit ? 0.9 : 0.25,
      );
      if (lit) {
        _bloom(canvas, at, 16 + 6 * _kick, _gold, 0.35);
      }
    }

    // The comet's head
    final head = _head;
    _bloom(
      canvas,
      head,
      14 + 10 * s1 + 10 * s3 + kick * 12 + flash * 30,
      Color.lerp(_accent, _white, 0.3)!,
      0.8,
    );
    _dot(head, 3.5 + 1.5 * s2 + kick * 1.5, _white, 1);
  }

  void _renderCometFinale(Canvas canvas, double f) {
    // The whole ring flashes white, then spins in fire, ice and gold
    final white = exp(-f * 3);
    final spin = _time * 2.2;
    final width = 4 + 8 * white + 2 * _kick;
    final palette = [_fire, _gold, _ice, _accent, _fire];
    _band(
      0,
      2 * pi,
      width,
      colorAt: (t) {
        final k = _fract(t - spin / (2 * pi)) * 4;
        final i = k.floor().clamp(0, 3);
        return Color.lerp(palette[i], palette[i + 1], k - i)!;
      },
    );
    _band(0, 2 * pi, width, color: _white, alpha: white);
    _band(0, 2 * pi, width * 4, color: _gold, alpha: 0.12 + 0.2 * white);
    // Four comets chase each other around
    for (var i = 0; i < 4; i++) {
      final a = spin + i * pi / 2;
      final pt = _polar(a, radius);
      _bloom(canvas, pt, 26 + 8 * _kick, i.isEven ? _fire : _ice, 0.8);
      _dot(pt, 4, _white, 1);
    }
  }

  // ---- beads ----

  double _beadAngle(int bar) => _start + (bar / max(1, _bars)) * 2 * pi;

  Color _beadColor(int bar, double s2) {
    if (s2 <= 0) {
      return _accent;
    }
    final alt = bar.isEven ? _fire : _ice;
    return Color.lerp(_accent, alt, 0.7 * s2)!;
  }

  void _renderBeads(Canvas canvas) {
    final n = _bars;
    if (n == 0) {
      return;
    }
    final p = _progress;
    final f = _finale;
    final s1 = _ramp(p, 0.25);
    final s2 = _ramp(p, 0.5);
    final s3 = _ramp(p, 0.75);
    final bar = _beat / 4;
    final lit = f != null ? n : bar.floor().clamp(0, n);
    final flash = _milestoneFlash;

    // Finale: a light runs around twice, faster and faster, and every
    // bead it passes pops
    double chaseAt = -1;
    if (f != null && f < _blowAt) {
      final k = f / _blowAt;
      chaseAt = (k * k * 2) % 1;
    }
    // Beads are gone once they blew up
    if (f != null && f >= _blowAt) {
      _renderBeadsAfterglow(canvas, f - _blowAt);
      return;
    }

    // Last quarter: lines join the lit beads, like a constellation
    if (s3 > 0 && lit > 1) {
      final step = 2 * pi / n;
      _band(
        _start,
        (lit - 1) * step,
        1,
        radiusAt: (a) => radius + _beadLift((a / step).round(), bar, s1),
        color: _white,
        alpha: 0.25 * s3 + 0.3 * flash,
        step: step,
      );
    }

    // The beads still to come: two draw calls for all of them
    final small = <double>[];
    final large = <double>[];
    for (var i = lit; i < n; i++) {
      final pt = _polar(_beadAngle(i), radius);
      (i % Song.bars == 0 ? large : small).addAll([pt.dx, pt.dy]);
    }
    _dots(canvas, small, 1.4, _white, 0.2);
    _dots(canvas, large, 2.4, _white, 0.35);

    for (var i = 0; i < lit; i++) {
      final big = i % Song.bars == 0;
      final a = _beadAngle(i);
      final age = _time - (_litAt[i] ?? -9);
      final pop = age < 0.4
          ? Curves.easeOutBack.transform(_clamp01(age / 0.4)) *
                (1 + 0.8 * exp(-age * 7))
          : 1.0;
      var size = (big ? 4.8 : 2.8) * pop;
      size *= 1 + 0.35 * s3 * _kick;
      var bright = 0.85;
      // A light runs from the top to the newest bead on every bar
      if (s2 > 0) {
        final run = _fract(bar) * lit;
        final d = (run - i).abs();
        if (d < 2) {
          bright += 0.6 * (1 - d / 2) * s2;
          size *= 1 + 0.4 * (1 - d / 2) * s2;
        }
      }
      if (chaseAt >= 0) {
        final d = ((chaseAt * n - i) % n + n) % n;
        if (d < 3) {
          size *= 1 + 1.2 * (1 - d / 3);
          bright += 1;
        }
      }
      bright += flash * 0.8;
      final pt = _polar(a, radius + _beadLift(i, bar, s1));
      final color = f != null ? _gold : _beadColor(i, s2);
      // Only the big beads, the newest one and the ones the light runs
      // over glow, so the ring doesn't turn into one blur
      if (big || i == lit - 1 || bright > 1.2) {
        _bloom(canvas, pt, size * 4, color, 0.45 * bright);
      }
      _dot(pt, size, color, bright);
      if (i == lit - 1 && f == null) {
        _dot(pt, size * 0.45, _white, 1);
      }
    }

    // The newest bead sparkles in the last quarter
    if (s3 > 0 && f == null && lit > 0 && _rnd.nextDouble() < 0.4) {
      _burst(
        _polar(_beadAngle(lit - 1), radius),
        1,
        speed: 50,
        colors: [_white, _gold],
      );
    }
    // During the chase, notes climb with it
    if (chaseAt >= 0) {
      final step = (chaseAt * 8).floor();
      if (step != _chaseStep) {
        _chaseStep = step;
        const scale = [0, 2, 4, 7, 9, 12, 14, 16];
        _scheduleNote(
          0,
          step.isEven ? 'ice' : 'fire',
          72 + _root + scale[step % 8],
          0.5,
        );
      }
    }
  }

  int _chaseStep = -1;

  /// How far a lit bead hops out on the beat: a wave from the newest bead
  /// back to the first
  double _beadLift(int i, double bar, double s1) {
    if (s1 <= 0) {
      return 0;
    }
    final lag = (bar - i) * 0.12;
    final phase = _fract(_beat - lag);
    return pow(1 - phase, 3).toDouble() * 5 * s1;
  }

  void _renderBeadsAfterglow(Canvas canvas, double t) {
    final a = exp(-t * 0.9);
    canvas.drawCircle(Offset.zero, radius, _stroke(_gold, 3 + 2 * _kick, a));
    canvas.drawCircle(Offset.zero, radius, _stroke(_gold, 16, 0.12 * a));
  }

  // ---- wave ----

  static const _spikes = 144;

  Color _waveColor(double along, double s2) {
    if (s2 <= 0) {
      return _accent;
    }
    final k = (sin(along * 2 + _time * 1.5) + 1) / 2;
    return Color.lerp(_accent, Color.lerp(_fire, _ice, k)!, 0.75 * s2)!;
  }

  void _renderWave(Canvas canvas) {
    final p = _progress;
    final f = _finale;
    final s1 = _ramp(p, 0.25);
    final s2 = _ramp(p, 0.5);
    final s3 = _ramp(p, 0.75);
    final flash = _milestoneFlash;
    final beatIndex = _beat.floor();

    // In the finale, the ring falls into the potato, then blows out
    var r = radius;
    var boom = 0.0;
    if (f != null) {
      if (f < _blowAt) {
        final k = Curves.easeInCubic.transform(_clamp01((f - 0.25) / 0.6));
        r = radius + (70 - radius) * k;
        boom = exp(-f * 5);
      } else {
        final t = f - _blowAt;
        r = 70 + (radius - 70) * Curves.elasticOut.transform(_clamp01(t / 1.1));
        boom = exp(-t * 2.5);
        _renderSunburst(canvas, t);
      }
    }

    final sweep = f != null ? 2 * pi : p * 2 * pi;
    // All spikes are one mesh of colored quads: a single draw call that
    // is cheap for the GPU (stroked lines with round caps are not)
    final mesh = _SpikeMesh();
    final tips = <double>[];
    final rest = <double>[];
    for (var i = 0; i < _spikes; i++) {
      final along = i / _spikes * 2 * pi;
      final a = _start + along;
      if (along > sweep) {
        final pt = _polar(a, r);
        rest.addAll([pt.dx, pt.dy]);
        continue;
      }
      final rnd = _hash(i, beatIndex);
      var len = 3.0 + 4 * _kick * (0.4 + rnd);
      len += s1 * 14 * _kick * rnd;
      len += s2 * 5 * _sixteenth * _hash(i, beatIndex * 4 + 1);
      len += s3 * 10 * _kick * rnd;
      len += flash * 22 * (0.5 + rnd);
      len += boom * 50 * (0.6 + rnd);
      // The newest part of the ring jumps the most
      final fresh = f == null ? exp(-(sweep - along) * 3) : 0.0;
      len += fresh * 8 * _kick;
      final color = f != null
          ? Color.lerp(_gold, _waveColor(along, 1), 0.5)!
          : _waveColor(along, s2);
      final width = 2.2 + s3;
      mesh.add(a, r, r + len, width, color, 0.85 * _visible);
      if (s2 > 0 || f != null) {
        // Half way: it mirrors inwards too
        mesh.add(
          a,
          r,
          r - len * 0.5,
          width,
          color,
          0.45 * (f != null ? 1 : s2) * _visible,
        );
      }
      if (s3 > 0 && len > 14) {
        final tip = _polar(a, r + len);
        tips.addAll([tip.dx, tip.dy]);
      }
    }
    _dots(canvas, rest, 1.1, _white, 0.18);
    mesh.draw(canvas, _fillPaint);
    _dots(canvas, tips, 1.6, _white, 0.8 * s3);
    // A thin line under the spikes
    final line = f != null ? _gold : _accent;
    _band(_start, sweep, 1.4, radiusAt: (_) => r, color: line, alpha: 0.6);
    if (f == null) {
      final head = _polar(_headAngle, r);
      _bloom(canvas, head, 18 + 14 * _kick + 20 * s3, _white, 0.7);
      _dot(head, 3 + _kick * 2, _white, 1);
    }
  }

  /// Rays from the potato after the wave ring blows out
  void _renderSunburst(Canvas canvas, double t) {
    final a = exp(-t * 1.1);
    if (a < 0.02) {
      return;
    }
    final paint = _bloomPaint..strokeCap = StrokeCap.round;
    const rays = 24;
    final turn = t * 0.4;
    for (var i = 0; i < rays; i++) {
      final ang = turn + i * 2 * pi / rays;
      final len =
          radius * (0.5 + 0.9 * Curves.easeOut.transform(_clamp01(t / 0.6)));
      paint
        ..strokeWidth = i.isEven ? 6 : 3
        ..shader = ui.Gradient.linear(_polar(ang, 80), _polar(ang, len), [
          (i.isEven ? _gold : _accent).withValues(alpha: 0.55 * a * _visible),
          (i.isEven ? _gold : _accent).withValues(alpha: 0),
        ]);
      canvas.drawLine(_polar(ang, 80), _polar(ang, len), paint);
    }
    paint.shader = null;
  }
}
