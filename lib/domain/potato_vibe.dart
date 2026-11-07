import 'dart:math';

import 'life_meter.dart';

/// How much the potato is enjoying the music, and how shaken it is.
///
/// Every orb the shield blocks plays a melody note, and every note gets the
/// potato more into the song ([groove]). An orb that gets through startles
/// it ([nerves]) and throws it off the song. Blocking more notes calms it
/// down again, so the player is always working to keep the potato happy.
///
/// The life bar sets the mood too: in its danger stage the potato never
/// fully relaxes, and with a full bar it grooves its hardest.
class PotatoVibe {
  /// Groove one note adds (about 8 notes in a row to be fully into it)
  static const perNote = 0.13;

  /// With no new note for this long, the groove starts to fade
  static const quietWindow = 1.6;

  /// Groove lost per second once it's quiet
  static const grooveFade = 0.18;

  /// Share of the groove a hit keeps
  static const grooveKeptOnHit = 0.2;

  /// Nerves lost per second (a hit takes about 4 seconds to shake off).
  /// The dizzy face covers the first 1.6 seconds, then the nervous look
  /// shows while it calms down.
  static const nervesFade = 0.25;

  /// Nerves each blocked note takes away, on top of [nervesFade]
  static const nervesPerNote = 0.08;

  /// Nerves never drop below this while the life bar is in danger
  static const dangerNerves = 0.45;

  /// How into the music the potato is, from 0 to 1
  double get groove => _groove;
  double _groove = 0;

  /// How shaken the potato is, from 0 to 1
  double get nerves => _nerves;
  double _nerves = 0;

  /// A short kick on every note (1 right after a note, then fades out fast),
  /// for the little hop and the "sing along" mouth
  double get kick => _kick;
  double _kick = 0;

  double _sinceNote = double.infinity;
  double _floor = 0;
  double _life = LifeMeter.start;

  /// Grooving and not shaken: 1 is a fully happy, dancing potato
  double get calm => _groove * (1 - _nerves);

  /// Eyes closed in bliss, only when it's really into it
  double get bliss => _smoothstep(0.55, 0.9, calm * _fullBarBoost);

  /// How big the dance is: a full life bar makes it dance harder
  double get dance => calm * _fullBarBoost;

  double get _fullBarBoost =>
      0.85 + 0.15 * _smoothstep(0.5, LifeMeter.stages[3], _life);

  /// The shield blocked an orb and played a note
  void onNote() {
    // Hard to get into the song while shaken
    _groove = min(1.0, _groove + perNote * (1 - 0.6 * _nerves));
    _nerves = max(_floor, _nerves - nervesPerNote);
    _sinceNote = 0;
    _kick = 1;
  }

  /// An orb got through and hit the potato
  void onHit() {
    _nerves = 1;
    _groove *= grooveKeptOnHit;
    _kick = 0;
  }

  /// Back to a neutral potato (new run, menu)
  void reset() {
    _groove = 0;
    _nerves = 0;
    _kick = 0;
    _sinceNote = double.infinity;
  }

  /// [life] is the life bar value, [playing] is false outside of a run,
  /// where the potato slowly settles down
  void update(double dt, {required double life, required bool playing}) {
    _life = life;
    _floor = playing && life < LifeMeter.danger ? dangerNerves : 0;
    _sinceNote += dt;
    _kick = max(0, _kick - dt * 5);
    if (!playing || _sinceNote > quietWindow) {
      _groove = max(0, _groove - grooveFade * dt * (playing ? 1 : 3));
    }
    if (_nerves > _floor) {
      _nerves = max(_floor, _nerves - nervesFade * dt);
    } else {
      // Ease into the danger floor instead of jumping to it
      _nerves = min(_floor, _nerves + dt);
    }
  }

  static double _smoothstep(double from, double to, double x) {
    final t = ((x - from) / (to - from)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}
