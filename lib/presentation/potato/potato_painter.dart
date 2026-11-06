import 'dart:math';
import 'dart:ui';

import 'potato_pose.dart';

/// Draws the potato with plain canvas calls.
///
/// The potato is drawn on a 500 x 500 artboard (the potato itself sits around
/// the middle of it), so callers scale the canvas to the size they need. See
/// [paintFitted]. All shapes, colors and positions are taken from the
/// original Rive file, so it looks the same as before.
///
/// Parts from back to front: shading, body, freckles, cheeks, eyebrows,
/// smile, eyes (with sparkles and heart pop-ups), frown, zigzag mouth.
abstract final class PotatoPainter {
  /// Size of the square artboard the potato is drawn on.
  static const artboardSize = 500.0;

  static const _ink = Color(0xFF462724);
  static const _outline = Color(0xFF472A26);
  static const _pink = Color(0xFFFF786F);
  static const _freckle = Color(0xFFC88855);
  static const _sparkle = Color(0xFFFEFFFF);
  static const _sparkleGreen = Color(0xFF3CCE20);
  static const _heartRed = Color(0xFFFF0058);
  static const _fireTint = Color(0x82F92424);
  static const _iceTint = Color(0x822CB3F5);

  static final _fill = Paint()..isAntiAlias = true;
  static final _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Draws the potato centered in a [boxSize] square at [offset], scaled so
  /// the 500 x 500 artboard fills the box.
  static void paintFitted(
    Canvas canvas,
    PotatoPose pose, {
    required double boxSize,
    Offset offset = Offset.zero,
  }) {
    final scale = boxSize / artboardSize;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    paint(canvas, pose);
    canvas.restore();
  }

  /// Draws the potato in artboard coordinates (0..500 on both axes).
  static void paint(Canvas canvas, PotatoPose pose) {
    _paintBody(canvas, pose);
    _paintFreckles(canvas);
    _paintCheeks(canvas);
    _paintBrows(canvas, pose);
    _paintSmile(canvas, pose);
    _paintEyes(canvas, pose);
    _paintFrown(canvas, pose);
    _paintZigzag(canvas, pose);
  }

  // ---------------------------------------------------------------- body --

  static void _paintBody(Canvas canvas, PotatoPose pose) {
    // Darker shading at the bottom of the potato.
    _inShape(
      canvas,
      const Offset(240.4013, 274.6576),
      () {
        _fill.shader = _shadowGradient;
        canvas.drawPath(_shadow, _fill);
      },
      scaleX: 1.0095,
      scaleY: 1.0711,
    );
    _inShape(canvas, const Offset(360.9677, 287.4581), () {
      _fill
        ..shader = null
        ..color = const Color(0xFFCF8C5A);
      canvas.drawPath(_bottomRim, _fill);
    });
    _inShape(canvas, const Offset(357.0317, 231.4609), () {
      _fill.shader = _upperShadingGradient;
      canvas.drawPath(_upperShading, _fill);
    });

    // The body: a light gradient that fades out toward the bottom, so the
    // shading above shows through.
    _inShape(canvas, _bodyOrigin, () {
      _fill.shader = _bodyGradient;
      canvas.drawPath(_body, _fill);
    });
    _inShape(
      canvas,
      const Offset(122.7228, 231.9391),
      () {
        _fill.shader = _highlightGradient;
        canvas.drawPath(_highlight, _fill);
      },
      scaleX: 1.0323,
      scaleY: 1.079,
    );
    _fill.shader = null;

    // Hit flashes over the skin, then the outline on top.
    _inShape(canvas, _bodyOrigin, () {
      _fillPath(canvas, _body, _iceTint, pose[PotatoProp.iceTint]);
      _fillPath(canvas, _body, _fireTint, pose[PotatoProp.fireTint]);
      _stroke
        ..color = _outline
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.butt;
      canvas.drawPath(_body, _stroke);
      _stroke.strokeCap = StrokeCap.round;
    });
  }

  static const _bodyOrigin = Offset(101.8396, 254.2873);

  /// The potato's outline in artboard coordinates
  static final bodyOutline = _body.shift(_bodyOrigin);

  static final _body = Path()
    ..moveTo(0, 0)
    ..cubicTo(0, 0, 1.66, -158.22, 147.09, -153.99)
    ..cubicTo(292.52, -149.75, 280.54, 0, 280.54, 0)
    ..cubicTo(280.54, 0, 282.45, 54.07, 266.41, 94.76)
    ..cubicTo(251.01, 133.86, 219.17, 159.6, 147.09, 162.02)
    ..cubicTo(72.96, 164.5, 30, 135.57, 11.97, 94.03)
    ..cubicTo(-6.05, 52.5, 0, 0, 0, 0)
    ..close();

  static final _bodyGradient = Gradient.linear(
    const Offset(145.0538, 162.1244),
    const Offset(147.0929, -154.0711),
    const [Color(0x00E0A774), Color(0xFFFDE5B7)],
  );

  static final _highlight = Path()
    ..moveTo(0, 0)
    ..cubicTo(0, 0, 8.81, -88.04, 86.26, -106.1)
    ..cubicTo(163.71, -124.16, 205.04, -68.7, 205.04, -68.7)
    ..cubicTo(205.04, -68.7, 226.25, -51.85, 230.86, 0)
    ..cubicTo(235.48, 51.85, 249.98, 88.89, 187.17, 124.59)
    ..cubicTo(124.37, 160.29, 52.09, 127.33, 47, 124.59)
    ..cubicTo(41.92, 121.85, -5.48, 102.54, -2.74, 45.86)
    ..close();

  static final _highlightGradient = Gradient.linear(
    const Offset(122.6014, 141.0831),
    const Offset(131.7949, -100.5151),
    const [Color(0xFFDFA673), Color(0xFFDFA774), Color(0xFFF5D3A2)],
    const [0, 0.0288, 1],
  );

  static final _shadow = Path()
    ..moveTo(0, -153)
    ..cubicTo(77.81, -153, 140.88, -87.84, 140.88, -7.46)
    ..cubicTo(140.88, 72.93, 107.94, 132.38, 30.14, 132.38)
    ..cubicTo(-14.99, 132.38, -65.81, 132.78, -100.11, 100.3)
    ..cubicTo(-124.95, 76.78, -140.88, 26.3, -140.88, -7.46)
    ..cubicTo(-140.88, -87.84, -77.81, -153, 0, -153)
    ..close();

  static final _shadowGradient = Gradient.linear(
    const Offset(8.2561, -105.9001),
    const Offset(11.2043, 132.3835),
    const [Color(0xFFE5B582), Color(0xFFB67957)],
  );

  static final _bottomRim = Path()
    ..moveTo(1, 0)
    ..cubicTo(1, 0, 8.76, 79.24, -71.9, 100.48)
    ..cubicTo(-152.56, 121.72, -197.66, 87.64, -197.66, 87.64)
    ..cubicTo(-197.66, 87.64, -227.42, 66.42, -234.14, 31.13)
    ..cubicTo(-240.87, -4.16, 1, 0, 1, 0)
    ..close();

  static final _upperShading = Path()
    ..moveTo(0, 0)
    ..cubicTo(0, 0, -21.2, -34.09, -62.58, -67.38)
    ..cubicTo(-103.96, -100.66, -88.66, -58.4, -88.66, -58.4)
    ..cubicTo(-88.66, -58.4, -106.81, -73.16, -142.01, -42.99)
    ..cubicTo(-177.2, -12.83, -228.13, 0, -228.13, 0)
    ..lineTo(-239.57, -10.82)
    ..lineTo(-247.96, -26.41)
    ..lineTo(-223.89, -78.05)
    ..lineTo(-183.94, -114.57)
    ..lineTo(-111.56, -131.24)
    ..lineTo(-65.07, -120.75)
    ..lineTo(-19.07, -100.52)
    ..lineTo(12.39, -53.25)
    ..cubicTo(12.39, -53.25, 15.89, -31.62, 15.89, -26.15)
    ..cubicTo(15.89, -20.67, 18.58, -17.14, 18.58, -17.14)
    ..lineTo(18.58, -10.82)
    ..close();

  static final _upperShadingGradient = Gradient.radial(
    const Offset(-247.9583, 0),
    194.18,
    const [Color(0xFFE6B887), Color(0xFFFBE0B2)],
  );

  // ------------------------------------------------------------ freckles --

  static void _paintFreckles(Canvas canvas) {
    _fill.color = _freckle;
    for (final (x, y, w, h) in _freckles) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        _fill,
      );
    }
  }

  static const _freckles = [
    (164.64, 359.13, 6.73, 7.38),
    (202.12, 283.64, 11.52, 12.64),
    (201.12, 358.64, 11.52, 12.64),
    (266.12, 329.64, 11.52, 12.64),
    (252.12, 220.64, 11.52, 12.64),
    (248.69, 164.08, 8.52, 9.35),
    (280.69, 158.08, 8.52, 9.35),
    (257.82, 130.95, 10.18, 11.17),
    (337.96, 208.05, 4.99, 5.47),
    (226.96, 205.05, 4.99, 5.47),
    (247.96, 240.05, 4.99, 5.47),
    (281.96, 286.05, 4.99, 5.47),
    (291.96, 356.05, 4.99, 5.47),
    (300.96, 294.05, 4.99, 5.47),
    (220.96, 349.05, 4.99, 5.47),
    (184.96, 302.05, 4.99, 5.47),
    (291.46, 312.56, 13.64, 12.86),
    (148.46, 306.56, 13.64, 12.86),
    (277.46, 188.56, 13.64, 12.86),
    (226.28, 183.57, 11.37, 10.72),
    (202.62, 158.44, 19.46, 18.69),
    (205.3, 317.8, 19.46, 18.69),
    (325.45, 327.14, 19.46, 18.69),
  ];

  // ---------------------------------------------------- cheeks and brows --

  /// The face parts (cheeks, brows, eyes) were laid out in a group that is
  /// shifted by this offset.
  static const _face = Offset(-169.5526, 90.4602);

  static void _paintCheeks(Canvas canvas) {
    _fill.color = _pink;
    _inShape(canvas, _face + const Offset(504.7333, 190.7564), () {
      canvas.drawRRect(_pill(33.8574, 17.4735), _fill);
    }, scaleY: 0.9822);
    _inShape(canvas, _face + const Offset(319.5062, 190.5455), () {
      canvas.drawRRect(_pill(33.8574, 17.4735), _fill);
    });
  }

  static void _paintBrows(Canvas canvas, PotatoPose pose) {
    _fill.color = _ink;
    _inShape(
      canvas,
      _face + const Offset(342.7701, 97.2783),
      () => canvas.drawRRect(_brow, _fill),
      angle: pose[PotatoProp.leftBrowAngle],
      scaleX: 1.1706,
    );
    _inShape(
      canvas,
      _face + const Offset(482.7701, 97.2783),
      () => canvas.drawRRect(_brow, _fill),
      angle: pose[PotatoProp.rightBrowAngle],
      scaleX: 1.1706,
    );
  }

  static final _brow = _pill(
    20.5342,
    10.9222,
  ).shift(const Offset(-0.0348, -0.2576));

  static RRect _pill(double width, double height) => RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: width, height: height),
    Radius.circular(min(width, height) / 2),
  );

  // --------------------------------------------------------------- mouth --

  static void _paintSmile(Canvas canvas, PotatoPose pose) {
    final opacity = pose[PotatoProp.smileOpacity];
    final scaleY = pose[PotatoProp.smileScaleY];
    if (opacity <= 0 || scaleY == 0) return;
    _inShape(canvas, const Offset(245.467, 280.8404), () {
      _inShape(
        canvas,
        Offset(-2.5234, pose[PotatoProp.mouthY]),
        () => _fillPath(
          canvas,
          _mouth,
          _ink,
          opacity * pose[PotatoProp.mouthOpacity],
        ),
        scaleX: pose[PotatoProp.mouthScaleX],
        scaleY: pose[PotatoProp.mouthScaleY],
      );
      _inShape(
        canvas,
        const Offset(11.6825, -8.5162),
        () => _fillPath(
          canvas,
          _tongue,
          _pink,
          opacity * pose[PotatoProp.tongueOpacity],
        ),
      );
    }, scaleY: scaleY);
  }

  static final _mouth = Path()
    ..moveTo(-0.04, -5.36)
    ..cubicTo(9.06, -5.02, 13, -8.9, 13.89, -9.59)
    ..cubicTo(14.76, -10.26, 16.16, -11.49, 16.94, -11.86)
    ..cubicTo(22.75, -14.59, 26.8, -8.8, 26.8, 0)
    ..cubicTo(26.8, 14.8, 14.8, 26.8, 0, 26.8)
    ..cubicTo(-14.8, 26.8, -26.8, 14.8, -26.8, 0)
    ..cubicTo(-26.8, -5.77, -25.83, -9.9, -22.87, -11.53)
    ..cubicTo(-20.91, -12.6, -17.06, -12.47, -15.67, -11.42)
    ..cubicTo(-14.21, -10.31, -14.51, -10.39, -13.53, -9.59)
    ..cubicTo(-12.09, -8.41, -7.49, -5.36, -0.04, -5.36)
    ..close();

  static final _tongue = Path()
    ..moveTo(-29.29, 0.69)
    ..cubicTo(-29.75, -3.26, -25.98, 3.33, -14.16, 3.33)
    ..cubicTo(-2.34, 3.33, 0.14, -4.09, 0.04, 1.32)
    ..cubicTo(-0.24, 16.47, -14.15, 15.55, -14.15, 15.55)
    ..cubicTo(-14.15, 15.55, -27.57, 15.55, -29.29, 0.69)
    ..close();

  static void _paintFrown(Canvas canvas, PotatoPose pose) {
    final opacity = pose[PotatoProp.frownOpacity];
    if (opacity <= 0) return;
    _inShape(
      canvas,
      const Offset(242.4294, 280.8722),
      () {
        _strokePath(canvas, _frown, 14.75, opacity);
      },
      scaleX: 0.7586,
      scaleY: pose[PotatoProp.frownScaleY],
    );
  }

  static final _frown = Path()
    ..moveTo(-26.91, 15.64)
    ..cubicTo(-26.91, 15.64, -32.54, -16.3, -1.22, -16.3)
    ..cubicTo(30.11, -16.3, 23.94, 16.22, 23.94, 16.22);

  static void _paintZigzag(Canvas canvas, PotatoPose pose) {
    final opacity = pose[PotatoProp.zigzagOpacity];
    if (opacity <= 0) return;
    _inShape(
      canvas,
      const Offset(197.4215, 298.5435),
      () {
        _strokePath(canvas, _zigzag, 8, opacity);
      },
      scaleX: 1.4,
      scaleY: 1.4,
    );
  }

  static final _zigzag = Path()
    ..moveTo(8.14, 0)
    ..lineTo(14.83, -10.41)
    ..lineTo(25.08, 0)
    ..lineTo(33.52, -10.74)
    ..lineTo(41.81, 0)
    ..lineTo(50.31, -10.41)
    ..lineTo(56.03, 0);

  // ---------------------------------------------------------------- eyes --

  static void _paintEyes(Canvas canvas, PotatoPose pose) {
    _fill.color = _ink;
    for (final (center, width) in const [
      (Offset(477.9332, 149.1771), 63.9749),
      (Offset(346.7722, 150.1771), 63.1761),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: _face + center, width: width, height: 65.3739),
        _fill,
      );
    }

    final scaleX = pose[PotatoProp.sparkleScaleX];
    final scaleY = pose[PotatoProp.sparkleScaleY];
    if (scaleX != 0 && scaleY != 0) {
      final size = pose[PotatoProp.sparkleSize];
      final star = _sparkleFor(size);
      final color = Color.lerp(
        _sparkle,
        _sparkleGreen,
        pose[PotatoProp.sparkleGreen],
      )!;
      for (final x in const [346.5571, 477.4041]) {
        _inShape(
          canvas,
          _face + Offset(x + pose[PotatoProp.sparkleX], 146.5725),
          () {
            _fill.color = color;
            canvas.drawPath(star, _fill);
            _stroke
              ..color = const Color(0xFFFFFFFF)
              ..strokeWidth = pose[PotatoProp.sparkleOutline]
              ..strokeJoin = StrokeJoin.miter
              ..strokeCap = StrokeCap.butt;
            canvas.drawPath(star, _stroke);
            _stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round;
          },
          scaleX: scaleX,
          scaleY: scaleY,
        );
      }
    }

    final heartOpacity = pose[PotatoProp.heartOpacity];
    final heartScale = pose[PotatoProp.heartScale];
    if (heartOpacity > 0 && heartScale != 0) {
      // Right heart first: the left one overlaps it when they grow.
      _paintHeart(
        canvas,
        center: _face + const Offset(477.9332, 146.8537),
        scaleX: 1.7156 * heartScale,
        scaleY: 1.7156 * heartScale,
        opacity: heartOpacity,
      );
      _paintHeart(
        canvas,
        center: _face + const Offset(345.5329, 146.7874),
        scaleX: 1.6094 * heartScale,
        scaleY: 1.7156 * heartScale,
        opacity: heartOpacity,
      );
    }
  }

  /// The sparkle path for [size], rebuilt only when the size changes (it
  /// only changes while a hit animation shrinks the sparkles).
  static Path _sparkleFor(double size) {
    if (size != _sparkleSizeCached) {
      _sparkleSizeCached = size;
      _sparkleCached = _sparkleStar(54.1 * size, 55.45 * size);
    }
    return _sparkleCached;
  }

  static double _sparkleSizeCached = 1;
  static Path _sparkleCached = _sparkleStar(54.1, 55.45);

  /// A four-pointed star with fully rounded corners: the sparkle in the eyes.
  static Path _sparkleStar(double width, double height) {
    const points = 4;
    const innerRadius = 0.3004;
    final corners = <Offset>[];
    for (var i = 0; i < points * 2; i++) {
      final angle = -pi / 2 + i * pi / points;
      final r = i.isEven ? 1.0 : innerRadius;
      corners.add(
        Offset(
          0.2645 + cos(angle) * width / 2 * r,
          0.1909 + sin(angle) * height / 2 * r,
        ),
      );
    }
    return _roundedPolygon(corners);
  }

  /// Rounds every corner of a polygon as much as possible (each corner
  /// starts halfway along its edges), the way Rive rounds a star.
  static Path _roundedPolygon(List<Offset> corners) {
    final path = Path();
    final n = corners.length;
    for (var i = 0; i < n; i++) {
      final pos = corners[i];
      final toPrev = corners[(i - 1 + n) % n] - pos;
      final toNext = corners[(i + 1) % n] - pos;
      final prevLength = toPrev.distance;
      final nextLength = toNext.distance;
      final prevDir = toPrev / prevLength;
      final nextDir = toNext / nextLength;
      final radius = min(prevLength, nextLength) / 2;
      final angle = atan2(
        prevDir.dx * nextDir.dy - prevDir.dy * nextDir.dx,
        prevDir.dx * nextDir.dx + prevDir.dy * nextDir.dy,
      ).abs();
      final ideal = min(
        radius,
        4 /
            3 *
            tan(angle / 4) *
            radius *
            (angle < pi / 2 ? 1 + cos(angle) : 2 - sin(angle)),
      );
      final start = pos + prevDir * radius;
      final c1 = pos + prevDir * (radius - ideal);
      final c2 = pos + nextDir * (radius - ideal);
      final end = pos + nextDir * radius;
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    }
    return path..close();
  }

  static void _paintHeart(
    Canvas canvas, {
    required Offset center,
    required double scaleX,
    required double scaleY,
    required double opacity,
  }) {
    _inShape(
      canvas,
      center,
      () {
        // Red heart with a white rim on top.
        _fillPath(canvas, _heartBack, _heartRed, opacity);
        _fillPath(canvas, _heartFront, _heartRed, opacity);
        _fillPath(canvas, _heartRim, const Color(0xFFFFFFFF), opacity);
      },
      scaleX: scaleX,
      scaleY: scaleY,
    );
  }

  static final _heartBack =
      (Path()
            ..moveTo(10.63, -3.35)
            ..cubicTo(9.67, 0.43, 6.73, 4.11, 0.93, 7.22)
            ..cubicTo(0.35, 7.53, -0.35, 7.53, -0.93, 7.22)
            ..cubicTo(-6.73, 4.11, -9.67, 0.43, -10.63, -3.35)
            ..cubicTo(-9.86, -5.48, -7.95, -6.99, -5.7, -7.26)
            ..cubicTo(-3.45, -7.53, -1.24, -6.5, 0, -4.61)
            ..cubicTo(1.25, -6.5, 3.46, -7.52, 5.71, -7.26)
            ..cubicTo(7.95, -6.99, 9.86, -5.48, 10.63, -3.35)
            ..close())
          .shift(const Offset(0, -1.0));

  static final _heartFront =
      (Path()
            ..moveTo(11, -3.89)
            ..cubicTo(11, 1.11, 8, 6.11, 0, 10.11)
            ..cubicTo(-8, 6.11, -11, 1.11, -11, -3.89)
            ..cubicTo(-11, -4.59, -10.88, -5.28, -10.63, -5.94)
            ..cubicTo(-9.86, -8.07, -7.95, -9.58, -5.7, -9.85)
            ..cubicTo(-3.45, -10.11, -1.25, -9.09, 0, -7.2)
            ..cubicTo(1.25, -9.09, 3.45, -10.11, 5.7, -9.85)
            ..cubicTo(7.95, -9.58, 9.86, -8.07, 10.63, -5.94)
            ..cubicTo(10.88, -5.28, 11, -4.59, 11, -3.89)
            ..close())
          .shift(const Offset(0, 1.6));

  /// A heart outline: the outer heart minus a smaller inner heart.
  static final _heartRim =
      (Path()
            ..moveTo(5, -10.74)
            ..cubicTo(3.12, -10.74, 1.32, -9.99, 0, -8.64)
            ..cubicTo(-1.99, -10.67, -5.01, -11.3, -7.65, -10.22)
            ..cubicTo(-10.28, -9.15, -12, -6.59, -12, -3.74)
            ..cubicTo(-12, 0.42, -10, 6.38, -0.45, 11.16)
            ..cubicTo(-0.17, 11.3, 0.17, 11.3, 0.45, 11.16)
            ..cubicTo(10, 6.38, 12, 0.42, 12, -3.74)
            ..cubicTo(12, -7.61, 8.86, -10.74, 5, -10.74)
            ..close()
            ..moveTo(0, 9.14)
            ..cubicTo(-6.64, 5.71, -10, 1.37, -10, -3.74)
            ..cubicTo(-10, -5.95, -8.55, -7.89, -6.44, -8.53)
            ..cubicTo(-4.33, -9.16, -2.05, -8.34, -0.83, -6.5)
            ..cubicTo(-0.64, -6.24, -0.33, -6.08, 0, -6.08)
            ..cubicTo(0.33, -6.08, 0.64, -6.24, 0.83, -6.5)
            ..cubicTo(2.05, -8.34, 4.33, -9.16, 6.44, -8.53)
            ..cubicTo(8.55, -7.89, 10, -5.95, 10, -3.74)
            ..cubicTo(10, 1.37, 6.64, 5.71, 0, 9.14)
            ..close())
          .shift(const Offset(0, 1.4))
        ..fillType = PathFillType.evenOdd;

  // ------------------------------------------------------------- helpers --

  /// Runs [draw] with the canvas moved to [origin], then rotated by [angle]
  /// and scaled.
  static void _inShape(
    Canvas canvas,
    Offset origin,
    void Function() draw, {
    double angle = 0,
    double scaleX = 1,
    double scaleY = 1,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (angle != 0) canvas.rotate(angle);
    if (scaleX != 1 || scaleY != 1) canvas.scale(scaleX, scaleY);
    draw();
    canvas.restore();
  }

  static void _fillPath(Canvas canvas, Path path, Color color, double opacity) {
    if (opacity <= 0) return;
    _fill
      ..shader = null
      ..color = color.withValues(alpha: color.a * opacity.clamp(0, 1));
    canvas.drawPath(path, _fill);
  }

  static void _strokePath(
    Canvas canvas,
    Path path,
    double width,
    double opacity,
  ) {
    _stroke
      ..color = _ink.withValues(alpha: opacity.clamp(0, 1))
      ..strokeWidth = width;
    canvas.drawPath(path, _stroke);
  }
}
