import 'dart:math';

/// How holding a side turns the shields
enum ShieldSteeringStyle {
  /// The old feel: full speed the moment a side is pressed
  classic,

  /// A tap nudges the shields a little, holding speeds them up to a cap
  ramp,

  /// One constant speed, slower than [classic]
  steady;

  static ShieldSteeringStyle? tryParse(String? name) {
    for (final style in values) {
      if (style.name == name) {
        return style;
      }
    }
    return null;
  }
}

/// Turns "which side is held" into how far the shields turn each frame
class ShieldSteering {
  ShieldSteering({this.style = defaultStyle});

  static const defaultStyle = ShieldSteeringStyle.ramp;

  static const classicSpeed = pi * 1.8;
  static const steadySpeed = pi * 1.2;

  /// The ramp starts slow so a tap only nudges the shields
  static const rampStartSpeed = pi * 0.6;
  static const rampMaxSpeed = pi * 1.6;

  /// How long a side must be held for the ramp to reach [rampMaxSpeed]
  static const rampDuration = 0.45;

  ShieldSteeringStyle style;

  int _direction = 0;
  double _heldFor = 0;

  /// -1 turns counter clockwise (left), 1 clockwise (right), 0 stops
  int get direction => _direction;

  set direction(int value) {
    final direction = value.sign;
    if (direction == _direction) {
      return;
    }
    // A new press (or a switch of side) starts the ramp over
    _direction = direction;
    _heldFor = 0;
  }

  /// The current turning speed in radians per second, signed
  double get velocity => _direction * speedAfter(style, _heldFor);

  /// How fast a side held for [heldFor] seconds turns the shields
  static double speedAfter(ShieldSteeringStyle style, double heldFor) =>
      switch (style) {
        ShieldSteeringStyle.classic => classicSpeed,
        ShieldSteeringStyle.steady => steadySpeed,
        ShieldSteeringStyle.ramp => _rampSpeed(heldFor),
      };

  static double _rampSpeed(double heldFor) {
    final t = (heldFor / rampDuration).clamp(0.0, 1.0);
    // Eases in, so short taps stay small and a long hold feels like a push
    return rampStartSpeed + (rampMaxSpeed - rampStartSpeed) * t * t;
  }

  /// How far (radians) a side held for [heldFor] seconds turns the shields
  static double turnAfter(ShieldSteeringStyle style, double heldFor) {
    switch (style) {
      case ShieldSteeringStyle.classic:
        return classicSpeed * heldFor;
      case ShieldSteeringStyle.steady:
        return steadySpeed * heldFor;
      case ShieldSteeringStyle.ramp:
        final rampTime = min(heldFor, rampDuration);
        final ramp =
            rampStartSpeed * rampTime +
            (rampMaxSpeed - rampStartSpeed) *
                rampTime *
                rampTime *
                rampTime /
                (3 * rampDuration * rampDuration);
        return ramp + rampMaxSpeed * max(0.0, heldFor - rampDuration);
    }
  }

  /// Advances by [dt] seconds and returns how far the shields turn (signed)
  double update(double dt) {
    if (_direction == 0) {
      return 0;
    }
    final turn = turnAfter(style, _heldFor + dt) - turnAfter(style, _heldFor);
    _heldFor += dt;
    return _direction * turn;
  }

  void reset() {
    _direction = 0;
    _heldFor = 0;
  }
}
