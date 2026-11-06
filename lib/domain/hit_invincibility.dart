import 'dart:math';

/// A short safe window after the potato gets hit, like most games give you.
///
/// While it runs, orbs that reach the potato do no damage, and the potato
/// blinks so the player can see it. The blink starts fast and slows down,
/// so you can feel when the window is about to end.
class HitInvincibility {
  /// How long the potato is safe after a hit, in seconds
  static const duration = 1.6;

  /// The lowest opacity of the potato during a blink
  static const minOpacity = 0.25;

  /// Blinks per second at the start and at the end of the window
  static const startBlinksPerSecond = 9.0;
  static const endBlinksPerSecond = 4.0;

  double _left = 0;
  double _phase = 0;

  /// True while orbs can't hurt the potato
  bool get isActive => _left > 0;

  /// 0 when idle, 1 right after a hit
  double get remaining => _left / duration;

  /// Start (or restart) the safe window
  void trigger() {
    _left = duration;
    _phase = 0;
  }

  /// End the safe window right away, e.g. on game over or restart
  void reset() {
    _left = 0;
    _phase = 0;
  }

  void update(double dt) {
    if (_left <= 0) {
      return;
    }
    final speed =
        endBlinksPerSecond +
        (startBlinksPerSecond - endBlinksPerSecond) * remaining;
    _phase += speed * dt;
    _left = max(0, _left - dt);
  }

  /// The potato's opacity right now: 1 when idle, blinking while active
  double get opacity {
    if (!isActive) {
      return 1;
    }
    // A smooth blink, starting at full so the hit reaction is still visible
    final wave = 0.5 + 0.5 * cos(_phase * 2 * pi);
    return minOpacity + (1 - minOpacity) * wave;
  }
}
