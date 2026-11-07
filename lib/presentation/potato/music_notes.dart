import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:save_the_potato/domain/game_constants.dart';

/// Small music notes that drift out of the potato's ear cups on the beat of
/// the song while it's calm and lost in the music.
///
/// They don't come from blocked orbs: [onBeat] is called on every beat of
/// the song, and a note comes out every two beats, one ear cup then the
/// other. They only show in the calm (flow) state, so they feel like a
/// reward for playing well.
///
/// A small fixed pool drawn with a few canvas calls, no components per note.
class MusicNotes extends PositionComponent {
  MusicNotes({
    required super.size,
    required this.bodyOffset,
    super.position,
    super.priority,
  });

  /// Where the potato's body is moved to by its dance, in local pixels, so
  /// the notes stay on it
  final Offset Function() bodyOffset;

  static const _maxNotes = 6;
  static const _life = 1.1;

  /// How long the pop to full size takes
  static const _popTime = 0.18;

  final _notes = List.generate(_maxNotes, (_) => _Note());
  final _rnd = Random();
  final _paint = Paint()..isAntiAlias = true;
  final _stem = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  int _next = 0;

  /// Where the ear cups are, as a share of [size] from the center
  static const _cupX = 0.48;
  static const _cupY = -0.05;

  static const _white = Color(0xFFFFFFFF);

  /// Called on each beat of the song. [beat] counts the beats.
  /// [flow] (0..1) is how deep in the calm state the potato is: no notes
  /// below half, and the deeper, the brighter.
  void onBeat(int beat, {required double flow}) {
    final s = flow.clamp(0.0, 1.0);
    // One note every two beats, alternating fire and ice
    if (beat.isOdd || s < 0.5) return;
    _spawn(fire: (beat ~/ 2).isEven, strength: s);
  }

  void _spawn({required bool fire, required double strength}) {
    final note = _notes[_next];
    _next = (_next + 1) % _maxNotes;
    final side = fire ? -1.0 : 1.0;
    note
      ..age = 0
      ..alive = true
      ..fire = fire
      ..pair = _rnd.nextDouble() < 0.25
      ..strength = strength
      ..x = side * size.x * (_cupX + 0.02)
      ..y = size.y * (_cupY - 0.12)
      ..vx = side * (6 + _rnd.nextDouble() * 4)
      ..vy = -(30 + _rnd.nextDouble() * 8)
      ..wobble = _rnd.nextDouble() * pi * 2;
  }

  void clear() {
    for (final note in _notes) {
      note.alive = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final note in _notes) {
      if (!note.alive) continue;
      note.age += dt;
      if (note.age >= _life) {
        note.alive = false;
        continue;
      }
      note.x += note.vx * dt + sin(note.age * 6 + note.wobble) * 6 * dt;
      note.y += note.vy * dt;
      note.vy *= pow(0.4, dt).toDouble();
    }
  }

  @override
  void render(Canvas canvas) {
    final body = bodyOffset();
    canvas.save();
    canvas.translate(size.x / 2 + body.dx, size.y / 2 + body.dy);
    for (final note in _notes) {
      if (!note.alive) continue;
      final t = note.age / _life;
      final opacity = (1 - t * t) * note.strength;
      final scale = 1.1 * _pop(note.age / _popTime);
      canvas.save();
      canvas.translate(note.x, note.y);
      canvas.rotate(sin(note.age * 4 + note.wobble) * 0.2);
      canvas.scale(scale);
      _drawGlowNote(canvas, note.fire, note.pair, opacity);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawGlowNote(Canvas canvas, bool fire, bool pair, double opacity) {
    final colors = fire ? GameConstants.redColors : GameConstants.blueColors;
    _paint.color = colors[1].withValues(alpha: 0.22 * opacity);
    canvas.drawCircle(const Offset(1.5, -3), 10, _paint);
    _drawNote(canvas, pair, colors[1].withValues(alpha: opacity), extra: 1.8);
    _drawNote(
      canvas,
      pair,
      Color.lerp(colors[0], _white, 0.45)!.withValues(alpha: opacity),
    );
  }

  /// Grows a bit past full size and settles back
  static double _pop(double t) {
    if (t >= 1) return 1;
    const c = 2.2;
    final u = t - 1;
    return max(0.0, 1 + (c + 1) * u * u * u + c * u * u);
  }

  void _drawNote(Canvas canvas, bool pair, Color color, {double extra = 0}) {
    _paint.color = color;
    _stem
      ..color = color
      ..strokeWidth = 1.8 + extra;
    if (pair) {
      _drawHead(canvas, const Offset(-4, 3), extra);
      _drawHead(canvas, const Offset(5, 1), extra);
      canvas.drawLine(const Offset(-1.2, 2.4), const Offset(-1.2, -9), _stem);
      canvas.drawLine(const Offset(7.8, 0.4), const Offset(7.8, -11), _stem);
      _stem.strokeWidth = 3 + extra;
      canvas.drawLine(const Offset(-1.2, -9), const Offset(7.8, -11), _stem);
    } else {
      _drawHead(canvas, const Offset(0, 3), extra);
      canvas.drawLine(const Offset(2.8, 2.4), const Offset(2.8, -10), _stem);
      canvas.drawPath(_flag, _stem);
    }
  }

  void _drawHead(Canvas canvas, Offset at, double extra) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 6.4 + extra,
        height: 4.6 + extra,
      ),
      _paint,
    );
    canvas.restore();
  }

  static final _flag = Path()
    ..moveTo(2.8, -10)
    ..cubicTo(5, -7.5, 8.5, -6.5, 7.5, -2.5);
}

class _Note {
  bool alive = false;
  bool fire = true;
  bool pair = false;
  double age = 0;
  double strength = 1;
  double x = 0, y = 0, vx = 0, vy = 0;
  double wobble = 0;
}
