import 'dart:math';

import 'package:save_the_potato/domain/potato_vibe.dart';

import 'potato_pose.dart';

/// Turns how the potato feels about the music ([PotatoVibe]) into movement
/// of its face and body, on the beat of the song.
///
/// - Into the music: nods and bounces on every beat, sways every two beats,
///   hops and sings along with each blocked note, and closes its eyes in
///   bliss when it's fully into it. The headphones thump with the beat.
/// - Shaken by a hit: stops dancing, trembles, glances around, worried
///   brows, wobbly mouth, and its headphones get knocked askew.
///
/// It only writes the props that no clip uses, so hit, scared and amazed
/// animations keep playing on top as before.
class PotatoVibeMotion {
  PotatoVibeMotion(this.vibe);

  final PotatoVibe vibe;

  /// Seconds per beat of the song
  static const beatSeconds = 0.5;

  double _time = 0;
  double _headphones = 0;
  double _tilt = 0;
  double _tiltVelocity = 0;
  double _faceCalm = 1;

  /// Gets the headphones knocked: called on a hit, [side] is -1 or 1
  void knock(double side) {
    _tiltVelocity += side * 3.2;
  }

  /// Puts the headphones on right away, without dropping them in
  void wearHeadphones() => _headphones = 1;

  /// [songTime] is where the music is (beats land on multiples of
  /// [beatSeconds]). [headphonesOn] puts them on or takes them off.
  /// [faceFree] is false while a clip (hit, scared, amazed, dying) owns the
  /// face, so the closed blissful eyes and the singing mouth wait for it.
  void update(
    double dt,
    PotatoPose pose, {
    required double songTime,
    required bool headphonesOn,
    required bool faceFree,
  }) {
    _time += dt;
    final beat = songTime / beatSeconds;
    final phase = beat - beat.floorToDouble();

    _faceCalm = _approach(_faceCalm, faceFree ? 1 : 0, dt * 6);
    final dance = vibe.dance;
    final nerves = vibe.nerves;
    final kick = vibe.kick;

    // A nod down onto every beat, then back up: sharp down, soft up
    final nod = pow(1 - phase, 3).toDouble();
    // A sway to one side, then the other, every two beats
    final sway = sin(pi * beat);

    // Trembling: two fast wobbles that never line up
    final shake = nerves * nerves;
    final trembleX = (sin(_time * 53) + 0.6 * sin(_time * 31)) * 3.2 * shake;
    final trembleAngle = sin(_time * 47) * 0.018 * shake;

    pose[PotatoProp.bodyX] = sway * 7 * dance + trembleX;
    pose[PotatoProp.bodyY] = nod * 10 * dance - kick * 9 * dance;
    pose[PotatoProp.bodyAngle] = sway * 0.06 * dance + trembleAngle;
    pose[PotatoProp.bodyScaleX] = 1 + 0.035 * nod * dance - 0.01 * kick;
    pose[PotatoProp.bodyScaleY] = 1 - 0.05 * nod * dance + 0.03 * kick * dance;

    // Nervous glances: looks one way, then the other
    final glance = sin(_time * 2.9) + 0.5 * sin(_time * 7.3);
    pose[PotatoProp.glanceX] = glance.clamp(-1.0, 1.0) * 8 * nerves;

    pose[PotatoProp.eyeBliss] = vibe.bliss * _faceCalm;
    pose[PotatoProp.sing] = kick * min(1, dance * 1.5) * _faceCalm;
    pose[PotatoProp.browWorry] = _smoothstep(0.1, 0.6, nerves);
    pose[PotatoProp.nervousMouth] = _smoothstep(0.35, 0.75, nerves) * _faceCalm;

    // Headphones: drop in at the start of a run, lift away at the end
    _headphones = _approach(_headphones, headphonesOn ? 1 : 0, dt * 2.2);
    pose[PotatoProp.headphones] = _easeOutBack(_headphones);

    // Knocked headphones: a springy tilt that settles back as it calms down
    const stiffness = 60.0;
    final damping = 6.0 + 10 * (1 - nerves);
    _tiltVelocity += (-stiffness * _tilt - damping * _tiltVelocity) * dt;
    _tilt += _tiltVelocity * dt;
    _tilt = _tilt.clamp(-0.35, 0.35);
    // While shaken they stay a bit crooked
    final crooked = 0.12 * _smoothstep(0.3, 0.9, nerves) * _tilt.sign;
    pose[PotatoProp.headphonesTilt] = _tilt + crooked;
    pose[PotatoProp.headphonesPulse] = nod * (0.3 + 0.7 * dance) + 0.9 * kick;
  }

  static double _approach(double from, double to, double step) =>
      from < to ? min(to, from + step) : max(to, from - step);

  static double _easeOutBack(double t) {
    if (t <= 0 || t >= 1) return t;
    const c = 1.7;
    final u = t - 1;
    return 1 + (c + 1) * u * u * u + c * u * u;
  }

  static double _smoothstep(double from, double to, double x) {
    final t = ((x - from) / (to - from)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}
