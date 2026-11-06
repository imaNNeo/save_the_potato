import 'dart:typed_data';

/// Every value of the potato's face that an animation can move.
///
/// [rest] is the value the potato has when nothing is playing. The numbers
/// come from the original Rive file, so the code-drawn potato keeps the exact
/// same look. Angles are in radians, positions in artboard units (the potato
/// is drawn on a 500 x 500 artboard).
enum PotatoProp {
  /// Horizontal offset of both eye sparkles (looking left / right).
  sparkleX(0),

  /// Width scale of the white sparkle inside each eye.
  sparkleScaleX(0.9596),

  /// Height scale of the white sparkle inside each eye. 0 hides it (blink).
  sparkleScaleY(1.1259),

  /// Size of the sparkle's star shape (shrinks when the potato gets hit).
  sparkleSize(1),

  /// 0 = white sparkle, 1 = green sparkle (amazed).
  sparkleGreen(0),

  /// Thickness of the white outline around the sparkle.
  sparkleOutline(1),

  leftBrowAngle(-0.3539),
  rightBrowAngle(0.3249),

  /// The dark open mouth inside the smile.
  mouthY(-9.435),
  mouthScaleX(0.9486),
  mouthScaleY(1),
  mouthOpacity(1),

  /// The pink tongue inside the smile.
  tongueOpacity(1),

  /// The whole smile (dark mouth + tongue).
  smileOpacity(1),
  smileScaleY(1),

  /// The zigzag mouth used when the potato is scared or hurt.
  zigzagOpacity(0),

  /// The upside-down mouth of the dead potato.
  frownOpacity(0),
  frownScaleY(0.7586),

  /// The hearts that pop over the eyes when a heart is collected.
  heartOpacity(0),
  heartScale(1),

  /// Red and blue skin flashes when a fire or ice orb hits the potato.
  fireTint(0),
  iceTint(0);

  const PotatoProp(this.rest);

  final double rest;
}

/// The current value of every [PotatoProp].
///
/// Animations write into a pose and the painter reads from it. A value stays
/// where the last animation left it until another animation moves it, which
/// is how Rive's state machine behaved as well.
class PotatoPose {
  PotatoPose() {
    reset();
  }

  final Float64List _values = Float64List(PotatoProp.values.length);

  double operator [](PotatoProp prop) => _values[prop.index];

  void operator []=(PotatoProp prop, double value) =>
      _values[prop.index] = value;

  /// Puts every value back to its [PotatoProp.rest] value.
  void reset() {
    for (final prop in PotatoProp.values) {
      _values[prop.index] = prop.rest;
    }
  }
}
