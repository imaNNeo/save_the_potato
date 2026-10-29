import 'dart:math';

/// How a damped spring moves after a kick: out to 1, a smaller swing back,
/// and rest.
///
/// It's worked out from the time since the kick, so long frames can't make
/// it blow up.
class DampedSpring {
  DampedSpring({required this.frequency, required this.damping})
    : assert(damping > 0 && damping < 1),
      _dampedFrequency = frequency * sqrt(1 - damping * damping) {
    final peakTime =
        atan(_dampedFrequency / (damping * frequency)) / _dampedFrequency;
    _peak =
        exp(-damping * frequency * peakTime) * sin(_dampedFrequency * peakTime);
  }

  /// In radians per second
  final double frequency;

  /// Between 0 and 1, the lower the more it bounces
  final double damping;

  final double _dampedFrequency;
  late final double _peak;

  /// Where the spring is [time] seconds after the kick
  double at(double time) =>
      exp(-damping * frequency * time) * sin(_dampedFrequency * time) / _peak;
}
