import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:save_the_potato/domain/game_constants.dart';

/// Little music notes that float up out of the headphones when a blocked
/// orb plays a note and the potato is enjoying it.
///
/// A small fixed pool drawn with a few canvas calls, no components per note.
class MusicNotes extends PositionComponent {
  MusicNotes({required super.size, super.position, super.priority});

  static const _maxNotes = 10;
  static const _life = 1.3;

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

  /// A note flies out of the ear cup on the side of [fire] (fire on the left,
  /// ice on the right), as big as [strength] (0..1) says
  void spawn({required bool fire, required double strength}) {
    if (strength <= 0.05) return;
    final note = _notes[_next];
    _next = (_next + 1) % _maxNotes;
    final side = fire ? -1.0 : 1.0;
    note
      ..age = 0
      ..alive = true
      ..fire = fire
      ..pair = _rnd.nextDouble() < 0.3
      ..strength = strength
      ..x = size.x / 2 + side * size.x * _cupX
      ..y = size.y / 2 - size.y * 0.05
      ..vx = side * (14 + _rnd.nextDouble() * 16)
      ..vy = -(38 + _rnd.nextDouble() * 18)
      ..wobble = _rnd.nextDouble() * pi * 2
      ..spin = (_rnd.nextDouble() - 0.5) * 0.8;
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
      note.x += note.vx * dt + sin(note.age * 7 + note.wobble) * 12 * dt;
      note.y += note.vy * dt;
      note.vx *= pow(0.25, dt).toDouble();
      note.vy *= pow(0.55, dt).toDouble();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final note in _notes) {
      if (!note.alive) continue;
      final t = note.age / _life;
      // Pops in, then fades out
      final grow = min(1.0, t * 8);
      final opacity = (1 - t * t) * note.strength;
      final scale = (0.7 + 0.5 * note.strength) * (0.6 + 0.4 * grow);
      final colors = note.fire
          ? GameConstants.redColors
          : GameConstants.blueColors;
      canvas.save();
      canvas.translate(note.x, note.y);
      canvas.rotate(sin(note.age * 5 + note.wobble) * 0.25 + note.spin * t);
      canvas.scale(scale);
      // A soft glow behind, then the note
      _paint.color = colors[1].withValues(alpha: 0.3 * opacity);
      canvas.drawCircle(const Offset(1, -3), 9, _paint);
      _paint.color = colors[0].withValues(alpha: opacity);
      _stem
        ..color = colors[0].withValues(alpha: opacity)
        ..strokeWidth = 1.8;
      if (note.pair) {
        _drawHead(canvas, const Offset(-4, 3));
        _drawHead(canvas, const Offset(5, 1));
        canvas.drawLine(const Offset(-1.2, 2.4), const Offset(-1.2, -9), _stem);
        canvas.drawLine(const Offset(7.8, 0.4), const Offset(7.8, -11), _stem);
        _stem.strokeWidth = 3;
        canvas.drawLine(const Offset(-1.2, -9), const Offset(7.8, -11), _stem);
      } else {
        _drawHead(canvas, const Offset(0, 3));
        canvas.drawLine(const Offset(2.8, 2.4), const Offset(2.8, -10), _stem);
        canvas.drawPath(_flag, _stem);
      }
      canvas.restore();
    }
  }

  void _drawHead(Canvas canvas, Offset at) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 6.4, height: 4.6),
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
  double wobble = 0, spin = 0;
}
