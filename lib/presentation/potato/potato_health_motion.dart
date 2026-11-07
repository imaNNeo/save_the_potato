import 'dart:math';

import 'package:save_the_potato/domain/health_mood.dart';

import 'potato_pose.dart';

/// Shows the life left on the potato itself, see [HealthMood]:
///
/// - calm: eyes closed, a soft hum, rosy cheeks, a slow sway, and the
///   headphones glow slowly;
/// - normal: the music mood as it is (dancing, singing along);
/// - worried: worried brows, wobbly mouth, small scared eyes glancing around,
///   pale skin, trembling, and the headphones slip.
///
/// It runs after `PotatoVibeMotion` every frame and takes over the face, so
/// the face only depends on the life, while the dance still follows the
/// music. Every change of mood gives a little squash, so it gets noticed.
class PotatoHealthMotion {
  HealthMood get mood => _mood;
  HealthMood _mood = HealthMood.normal;

  /// How far into the calm mood it is (0..1), it eases in and out
  double get calm => _calm;
  double _calm = 0;
  double _worried = 0;
  double _faceFree = 1;
  double _pop = 0;
  double _time = 0;

  /// Back to normal right away (new run, menu)
  void reset() {
    _mood = HealthMood.normal;
    _calm = 0;
    _worried = 0;
    _pop = 0;
  }

  /// [life] is the life left, [playing] is false outside of a run (normal
  /// mood). [faceFree] is false while a clip (hit, scared, amazed, dying)
  /// owns the face.
  void update(
    double dt,
    PotatoPose pose, {
    required double life,
    required bool playing,
    required bool faceFree,
  }) {
    _time += dt;
    final next = playing
        ? HealthMood.of(life, current: _mood)
        : HealthMood.normal;
    if (next != _mood) {
      _mood = next;
      if (playing) _pop = 1;
    }
    _pop = max(0, _pop - dt * 2.5);
    final ease = 1 - exp(-6 * dt);
    _calm += ((_mood == HealthMood.calm ? 1 : 0) - _calm) * ease;
    _worried += ((_mood == HealthMood.worried ? 1 : 0) - _worried) * ease;
    _faceFree += ((faceFree ? 1 : 0) - _faceFree) * (1 - exp(-8 * dt));
    final free = _faceFree;

    // The face
    pose[PotatoProp.eyeBliss] = _calm * free;
    pose[PotatoProp.browWorry] = _worried;
    pose[PotatoProp.nervousMouth] = _worried * free;
    final hum = 0.15 * (0.5 + 0.5 * sin(_time * 2.4));
    pose[PotatoProp.sing] =
        pose[PotatoProp.sing] * (1 - _calm - _worried).clamp(0.0, 1.0) +
        hum * _calm * free;
    // No clip moves the sparkle size while the face is free, so it's set
    if (faceFree) {
      pose[PotatoProp.sparkleSize] = 1 - 0.4 * _worried;
    }
    final glance = sin(_time * 2.9) + 0.5 * sin(_time * 7.3);
    pose[PotatoProp.glanceX] = glance.clamp(-1.0, 1.0) * 9 * _worried;
    pose[PotatoProp.blush] = _calm;
    pose[PotatoProp.pale] = _worried;

    // The body: the music's dance in between, a slow sway when calm,
    // trembling when worried
    final dance = (1 - _calm - _worried).clamp(0.0, 1.0);
    final sway = sin(_time * pi * 0.9);
    final shake = (sin(_time * 53) + 0.6 * sin(_time * 31)) * 3.4;
    pose[PotatoProp.bodyX] =
        pose[PotatoProp.bodyX] * dance + sway * 10 * _calm + shake * _worried;
    pose[PotatoProp.bodyY] =
        pose[PotatoProp.bodyY] * dance +
        (1 - cos(_time * pi * 1.8)) * 3 * _calm +
        4 * _worried;
    pose[PotatoProp.bodyAngle] =
        pose[PotatoProp.bodyAngle] * dance +
        sway * 0.08 * _calm +
        sin(_time * 47) * 0.02 * _worried;
    final squash = sin(_pop * pi) * 0.07;
    pose[PotatoProp.bodyScaleX] =
        (1 + (pose[PotatoProp.bodyScaleX] - 1) * dance) * (1 + squash);
    pose[PotatoProp.bodyScaleY] =
        (1 + (pose[PotatoProp.bodyScaleY] - 1) * dance - 0.04 * _worried) *
        (1 - squash);

    // The headphones glow slowly when calm and slip when worried
    pose[PotatoProp.headphonesTilt] =
        pose[PotatoProp.headphonesTilt] + 0.2 * _worried;
    pose[PotatoProp.headphonesPulse] =
        pose[PotatoProp.headphonesPulse] * (1 - 0.7 * _worried) * (1 - _calm) +
        (0.5 + 0.5 * sin(_time * pi * 1.8)) * 0.8 * _calm;
  }
}
