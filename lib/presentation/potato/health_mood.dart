import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:save_the_potato/domain/life_meter.dart';

import 'potato_painter.dart';
import 'potato_pose.dart';

/// Prototype: the potato's face shows how much life is left, instead of the
/// bar at the top. Picked with `?mood=<style>` on web.
enum HealthMoodStyle {
  /// Only the face changes: closed happy eyes, normal, worried
  face,

  /// The face, plus body language: a slow calm sway with rosy cheeks, the
  /// normal dance, or a pale trembling potato with sweat and its headphones
  /// slipping
  full,

  /// Like [full], with a fourth "uneasy" step between normal and worried, so
  /// every miss changes the face
  four;

  static final HealthMoodStyle? current = () {
    if (!kIsWeb) return null;
    final name = Uri.base.queryParameters['mood'];
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }();
}

/// How the potato feels about its life
enum HealthLevel { worried, uneasy, normal, calm }

/// Turns the life (see [LifeMeter]) into the potato's mood, on top of what
/// the music mood ([PotatoVibe]) does. It writes the props every frame after
/// `PotatoVibeMotion`, so the face always reads as the life left, and draws
/// the extras through [PotatoPainter.afterBody] and [PotatoPainter.afterFace].
class HealthMood {
  HealthMood(this.style);

  final HealthMoodStyle style;

  /// Life at or above this: calm, eyes closed, listening
  static const calmAt = 0.7;

  /// Below this the next miss ends the run
  static const worriedBelow = LifeMeter.danger;

  /// Below this (only in [HealthMoodStyle.four]): uneasy
  static const uneasyBelow = 0.4;

  HealthLevel level = HealthLevel.normal;

  double _calm = 0;
  double _uneasy = 0;
  double _worried = 0;
  double _faceFree = 1;
  double _pop = 0;
  double _time = 0;

  bool get _extras => style != HealthMoodStyle.face;

  void attach() {
    if (!_extras) return;
    PotatoPainter.afterBody = _paintSkin;
    PotatoPainter.afterFace = _paintFaceExtras;
  }

  void detach() {
    if (PotatoPainter.afterBody == _paintSkin) PotatoPainter.afterBody = null;
    if (PotatoPainter.afterFace == _paintFaceExtras) {
      PotatoPainter.afterFace = null;
    }
  }

  HealthLevel _levelFor(double life) {
    if (life < worriedBelow) return HealthLevel.worried;
    if (style == HealthMoodStyle.four) {
      final uneasyExit = level == HealthLevel.uneasy ? uneasyBelow + 0.02 : 0;
      if (life < max(uneasyBelow, uneasyExit)) return HealthLevel.uneasy;
    }
    // A little room so it doesn't flicker right at the line
    final calmEnter = level == HealthLevel.calm ? calmAt - 0.04 : calmAt;
    if (life >= calmEnter) return HealthLevel.calm;
    return HealthLevel.normal;
  }

  /// Call after the music mood wrote the pose
  void update(
    double dt,
    PotatoPose pose, {
    required double life,
    required bool playing,
    required bool faceFree,
  }) {
    _time += dt;
    final next = playing ? _levelFor(life) : HealthLevel.normal;
    if (next != level) {
      level = next;
      if (playing) _pop = 1;
    }
    _pop = max(0, _pop - dt * 2.5);
    final speed = 1 - exp(-6 * dt);
    _calm += ((level == HealthLevel.calm ? 1 : 0) - _calm) * speed;
    _uneasy += ((level == HealthLevel.uneasy ? 1 : 0) - _uneasy) * speed;
    _worried += ((level == HealthLevel.worried ? 1 : 0) - _worried) * speed;
    _faceFree += ((faceFree ? 1 : 0) - _faceFree) * (1 - exp(-8 * dt));

    final f = _faceFree;
    // The face: this replaces the music mood's bliss and worry, so it only
    // depends on the life
    pose[PotatoProp.eyeBliss] = _calm * f;
    pose[PotatoProp.browWorry] = max(_worried, 0.55 * _uneasy);
    pose[PotatoProp.nervousMouth] = _worried * f;
    // A small, flat mouth when uneasy, a soft hum when calm
    final hum = 0.15 * (0.5 + 0.5 * sin(_time * 2.4));
    pose[PotatoProp.sing] =
        pose[PotatoProp.sing] * (1 - _calm - _uneasy - _worried).clamp(0, 1) +
        hum * _calm * f -
        0.75 * _uneasy * f;
    // Small scared pupils
    // (no clip moves it while the face is free, so it is set, not scaled)
    if (faceFree) pose[PotatoProp.sparkleSize] = 1 - 0.4 * _worried;
    final glance = sin(_time * 2.9) + 0.5 * sin(_time * 7.3);
    pose[PotatoProp.glanceX] =
        glance.clamp(-1.0, 1.0) * (9 * _worried + 4 * _uneasy);

    if (!_extras) return;

    // Body: a slow sway when calm, still when uneasy, trembling when worried
    final dance = (1 - _calm - _uneasy * 0.8 - _worried).clamp(0.0, 1.0);
    final slow = sin(_time * pi * 0.9);
    final shake = (sin(_time * 53) + 0.6 * sin(_time * 31)) * 3.4;
    pose[PotatoProp.bodyX] =
        pose[PotatoProp.bodyX] * dance + slow * 10 * _calm + shake * _worried;
    pose[PotatoProp.bodyY] =
        pose[PotatoProp.bodyY] * dance +
        (1 - cos(_time * pi * 1.8)) * 3 * _calm +
        4 * _worried;
    pose[PotatoProp.bodyAngle] =
        pose[PotatoProp.bodyAngle] * dance +
        slow * 0.08 * _calm +
        sin(_time * 47) * 0.02 * _worried;
    final squash = sin(_pop * pi) * 0.07;
    pose[PotatoProp.bodyScaleX] =
        (1 + (pose[PotatoProp.bodyScaleX] - 1) * dance) * (1 + squash);
    pose[PotatoProp.bodyScaleY] =
        (1 + (pose[PotatoProp.bodyScaleY] - 1) * dance - 0.04 * _worried) *
        (1 - squash);

    // Headphones: glowing slowly when calm, slipping when worried
    pose[PotatoProp.headphonesTilt] =
        pose[PotatoProp.headphonesTilt] + 0.2 * _worried + 0.06 * _uneasy;
    pose[PotatoProp.headphonesPulse] =
        pose[PotatoProp.headphonesPulse] * (1 - 0.7 * _worried) * (1 - _calm) +
        (0.5 + 0.5 * sin(_time * pi * 1.8)) * 0.8 * _calm;
  }

  // ---- extras ----

  final _fill = Paint()..isAntiAlias = true;
  final _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  void _paintSkin(Canvas canvas, PotatoPose pose) {
    final on = pose[PotatoProp.headphones].clamp(0.0, 1.0);
    if (_worried * on > 0.01) {
      // Pale and a bit blue
      _fill
        ..shader = null
        ..color = const Color(0xFFA8CCF0).withValues(alpha: 0.3 * _worried);
      canvas.drawPath(PotatoPainter.bodyOutline, _fill);
    }
  }

  void _paintFaceExtras(Canvas canvas, PotatoPose pose) {
    final on = pose[PotatoProp.headphones].clamp(0.0, 1.0);
    if (on <= 0.01) return;
    // Rosy cheeks when calm
    final blush = _calm * on;
    if (blush > 0.01) {
      for (final c in const [Offset(150, 281), Offset(335, 281)]) {
        _fill
          ..color = const Color(0xFFFFFFFF)
          ..shader = Gradient.radial(c, 46, [
            const Color(0xFFFF5A7A).withValues(alpha: 0.6 * blush),
            const Color(0x00FF5A7A),
          ]);
        canvas.drawCircle(c, 46, _fill);
      }
      _fill.shader = null;
    }
    // Sweat drops sliding down when worried
    final sweat = (_worried + 0.4 * _uneasy) * on;
    if (sweat > 0.01) {
      for (final (start, phase, size) in const [
        (Offset(350, 140), 0.0, 1.0),
        (Offset(132, 160), 0.55, 0.8),
      ]) {
        if (style != HealthMoodStyle.four && _uneasy > _worried && size < 1) {
          continue;
        }
        final t = (_time / 1.5 + phase) % 1.0;
        final fade = (t < 0.15 ? t / 0.15 : (1 - t) / 0.85).clamp(0.0, 1.0);
        final at = start + Offset(t * 10, t * 70);
        _drop(canvas, at, 1.5 * size * (0.85 + 0.3 * t), sweat * fade);
      }
    }
  }

  void _drop(Canvas canvas, Offset at, double scale, double alpha) {
    final path = Path()
      ..moveTo(0, -30)
      ..cubicTo(6, -16, 18, -4, 18, 8)
      ..cubicTo(18, 19, 10, 26, 0, 26)
      ..cubicTo(-10, 26, -18, 19, -18, 8)
      ..cubicTo(-18, -4, -6, -16, 0, -30)
      ..close();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(scale);
    _stroke
      ..color = const Color(0xFF2A4A6A).withValues(alpha: alpha)
      ..strokeWidth = 6;
    canvas.drawPath(path, _stroke);
    _fill
      ..shader = null
      ..color = const Color(0xFF8FD8FF).withValues(alpha: alpha);
    canvas.drawPath(path, _fill);
    _fill.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.9);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-6, 8), width: 8, height: 12),
      _fill,
    );
    canvas.restore();
  }
}
