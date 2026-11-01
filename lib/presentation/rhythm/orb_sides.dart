import 'dart:math';

import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';

/// Decides where each orb comes in so the fire orbs arrive as one group on
/// one side and the ice orbs as one group on the opposite side.
///
/// Each group fans out over a wide arc, so the screen looks busy, but the
/// whole fan fits under the shield: holding the shield on the fire side
/// blocks every fire orb with its fire end and every ice orb with its ice
/// end. The sides themselves slowly turn every phrase, a little more as the
/// game gets harder, and keep turning around the arena, so fire is not
/// always on the right and ice is not always on the left. The player only
/// follows the turn with small, calm moves.
class OrbSides {
  OrbSides({Random? random}) : _rnd = random ?? Random();

  final Random _rnd;

  /// How long the sides stay on one course before they pick a new one:
  /// two bars of the song
  static const phraseSeconds = 4.0;

  /// The shield covers 45° each way from its middle. The groups fan out a
  /// bit less, so the shield blocks a whole group from one spot, with room
  /// to spare for the turn in between.
  static const _spreadEasy = 20 * pi / 180;
  static const _spreadHard = 30 * pi / 180;

  /// How far the sides turn over one phrase
  static const _turnEasy = (25 * pi / 180, 55 * pi / 180);
  static const _turnHard = (45 * pi / 180, 95 * pi / 180);

  /// Rifts of the same group never open closer than this to the last one
  static const _minStep = 9 * pi / 180;

  /// Where the fire side points at the start of each phrase
  final _phraseStarts = <double>[];
  int _turnDirection = 1;
  final _lastOffset = <OrbType, double>{};

  void reset() {
    _phraseStarts
      ..clear()
      ..add(_rnd.nextDouble() * pi * 2);
    _turnDirection = _rnd.nextBool() ? 1 : -1;
    _lastOffset.clear();
  }

  /// Where the fire side points at song time [time]: it eases from one
  /// phrase start to the next, so it never jerks.
  double fireSideAt(double time, double difficulty) {
    if (_phraseStarts.isEmpty) {
      reset();
    }
    final phrase = max(0, time ~/ phraseSeconds);
    while (_phraseStarts.length <= phrase + 1) {
      _phraseStarts.add(_phraseStarts.last + _nextTurn(difficulty));
    }
    final t = (time / phraseSeconds - phrase).clamp(0.0, 1.0);
    final eased = t * t * (3 - 2 * t);
    final from = _phraseStarts[phrase];
    return from + (_phraseStarts[phrase + 1] - from) * eased;
  }

  double _nextTurn(double difficulty) {
    final d = difficulty.clamp(0.0, 1.0);
    // Mostly keep turning the same way, so over a minute the sides travel
    // all the way around. Now and then turn back, to keep it lively.
    if (_rnd.nextDouble() < 0.25) {
      _turnDirection = -_turnDirection;
    }
    final low = _lerp(_turnEasy.$1, _turnHard.$1, d);
    final high = _lerp(_turnEasy.$2, _turnHard.$2, d);
    return _turnDirection * _lerp(low, high, _rnd.nextDouble());
  }

  /// The angle an orb of [type] that reaches the shield at [land] comes from
  double angleFor(OrbType type, double land, double difficulty) {
    final fireSide = fireSideAt(land, difficulty);
    final side = switch (type) {
      OrbType.fire => fireSide,
      OrbType.ice => fireSide + pi,
    };
    final spread = _lerp(_spreadEasy, _spreadHard, difficulty.clamp(0.0, 1.0));
    var offset = (_rnd.nextDouble() * 2 - 1) * spread;
    final last = _lastOffset[type];
    if (last != null && (offset - last).abs() < _minStep) {
      // Too close to the last rift of this group: jump to the other half
      // of the fan, so the rifts keep moving around
      offset = last > 0
          ? -spread * (0.3 + 0.7 * _rnd.nextDouble())
          : spread * (0.3 + 0.7 * _rnd.nextDouble());
    }
    _lastOffset[type] = offset;
    return side + offset;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
