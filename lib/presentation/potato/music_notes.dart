import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:save_the_potato/domain/game_constants.dart';

/// Music notes that pop out of the headphones when a blocked orb plays a
/// note, and float up.
///
/// Each one bursts out of its ear cup with a ring, pops to full size, and
/// rises with a glow behind it so it reads on the dark background. The
/// happier the potato, the bigger and brighter the notes.
///
/// A small fixed pool drawn with a few canvas calls, no components per note.
class MusicNotes extends PositionComponent {
  MusicNotes({required super.size, super.position, super.priority});

  static const _maxNotes = 14;
  static const _life = 1.8;

  /// How long the ring at the ear cup lasts when a note pops out
  static const _burstLife = 0.28;

  /// How long the pop to full size takes
  static const _popTime = 0.22;

  final _notes = List.generate(_maxNotes, (_) => _Note());
  final _rnd = Random();
  final _paint = Paint()..isAntiAlias = true;
  final _stem = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final _ring = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;
  int _next = 0;

  /// Prototype: when set, every note flies into this point (in this
  /// component's coordinates) instead of floating away, and [onHome] is
  /// called when it gets there.
  Offset Function()? homing;
  void Function()? onHome;

  /// How long a homing note takes to reach its target
  static const _homeTime = 0.55;

  /// Where the ear cups are, as a share of [size] from the center
  static const _cupX = 0.48;

  static const _white = Color(0xFFFFFFFF);

  /// A note pops out of the ear cup on the side of [fire] (fire on the
  /// left, ice on the right). [strength] (0..1) is how much the potato
  /// enjoys it: every note shows, the happier the potato the bigger and
  /// brighter.
  void spawn({required bool fire, required double strength}) {
    final note = _notes[_next];
    _next = (_next + 1) % _maxNotes;
    final side = fire ? -1.0 : 1.0;
    final cupX = size.x / 2 + side * size.x * _cupX;
    final cupY = size.y / 2 - size.y * 0.05;
    note
      ..age = 0
      ..alive = true
      ..fire = fire
      ..pair = _rnd.nextDouble() < 0.3
      ..strength = 0.5 + 0.5 * strength.clamp(0.0, 1.0)
      ..cupX = cupX
      ..cupY = cupY
      ..x = cupX
      ..y = cupY
      // Out past the shields fast, then a slow float
      ..vx = side * (34 + _rnd.nextDouble() * 22)
      ..vy = -(85 + _rnd.nextDouble() * 25)
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
      final target = homing;
      if (target != null) {
        if (note.age >= _homeTime) {
          note.alive = false;
          onHome?.call();
          continue;
        }
        // Pop out of the cup, then curve into the target
        final t = note.age / _homeTime;
        final to = target();
        final k = t * t * (3 - 2 * t);
        final outX = note.cupX + (note.cupX - size.x / 2) * 0.5;
        final outY = note.cupY - 14;
        final ax = note.cupX + (outX - note.cupX) * k;
        final ay = note.cupY + (outY - note.cupY) * k;
        final bx = outX + (to.dx - outX) * k;
        final by = outY + (to.dy - outY) * k;
        note.x = ax + (bx - ax) * k;
        note.y = ay + (by - ay) * k;
        continue;
      }
      if (note.age >= _life) {
        note.alive = false;
        continue;
      }
      note.x += note.vx * dt + sin(note.age * 7 + note.wobble) * 12 * dt;
      note.y += note.vy * dt;
      note.vx *= pow(0.12, dt).toDouble();
      note.vy *= pow(0.25, dt).toDouble();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final note in _notes) {
      if (!note.alive) continue;
      final homingNote = homing != null;
      final t = homingNote ? 0.0 : note.age / _life;
      final opacity = (1 - t * t * t) * note.strength;
      final shrink = homingNote
          ? 1 - 0.55 * pow(note.age / _homeTime, 2).toDouble()
          : 1.0;
      final scale =
          (1.5 + 0.7 * note.strength) * _pop(note.age / _popTime) * shrink;
      final colors = note.fire
          ? GameConstants.redColors
          : GameConstants.blueColors;

      // A ring bursts out of the ear cup as the note leaves it
      final burst = note.age / _burstLife;
      if (burst < 1) {
        _ring
          ..color = colors[0].withValues(alpha: (1 - burst) * note.strength)
          ..strokeWidth = 2.5 * (1 - burst) + 0.5;
        canvas.drawCircle(
          Offset(note.cupX, note.cupY),
          4 + 12 * sqrt(burst),
          _ring,
        );
      }

      canvas.save();
      canvas.translate(note.x, note.y);
      canvas.rotate(sin(note.age * 5 + note.wobble) * 0.25 + note.spin * t);
      canvas.scale(scale);
      // A soft glow behind, so it reads on the dark background
      _paint.color = colors[1].withValues(alpha: 0.18 * opacity);
      canvas.drawCircle(const Offset(1.5, -3), 14, _paint);
      _paint.color = colors[1].withValues(alpha: 0.3 * opacity);
      canvas.drawCircle(const Offset(1.5, -3), 9, _paint);
      // A saturated rim, then a bright, almost white note on top
      _drawNote(
        canvas,
        note.pair,
        colors[1].withValues(alpha: opacity),
        extra: 2.2,
      );
      _drawNote(
        canvas,
        note.pair,
        Color.lerp(colors[0], _white, 0.45)!.withValues(alpha: opacity),
      );
      canvas.restore();
    }
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
  double cupX = 0, cupY = 0;
  double wobble = 0, spin = 0;
}
