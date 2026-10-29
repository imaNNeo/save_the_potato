import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

/// Collects soft glowing shapes (discs, rings, streaks and bands along an
/// arc) as colored triangles and draws them all with one
/// [Canvas.drawVertices] call.
///
/// The edges fade out through the vertex colors, so the shapes look blurred
/// without the cost of a blur filter. They are added on top of what is below
/// them ([BlendMode.plus]), which makes them glow.
class GlowBatch {
  /// Circles use 24 to 96 segments, more when they are bigger
  static const _maxSegments = 96;
  static final _unitCos = Float32List.fromList([
    for (var i = 0; i <= _maxSegments; i++) cos(i / _maxSegments * 2 * pi),
  ]);
  static final _unitSin = Float32List.fromList([
    for (var i = 0; i <= _maxSegments; i++) sin(i / _maxSegments * 2 * pi),
  ]);

  static int _segmentsFor(double radius) => radius < 40
      ? 24
      : radius < 120
      ? 48
      : 96;

  /// Discs fade from the center to the edge through these rings, which is
  /// close to a gaussian falloff.
  static const _discRings = [0.28, 0.6, 1.0];
  static const _discRingAlphas = [0.62, 0.22, 0.0];

  static const _maxVertices = 1 << 16;

  final _paint = Paint()..blendMode = BlendMode.plus;

  var _positions = Float32List(2048);
  var _colors = Int32List(1024);
  var _indices = Uint16List(3072);
  int _vertexCount = 0;
  int _indexCount = 0;

  bool get isEmpty => _indexCount == 0;

  int get vertexCount => _vertexCount;

  void clear() {
    _vertexCount = 0;
    _indexCount = 0;
  }

  /// A soft disc, brightest in the center. [stretch] scales it along
  /// [angle] and [squash] across it, to make an ellipse.
  void addDisc(
    double x,
    double y,
    double radius,
    Color color,
    double opacity, {
    double angle = 0,
    double stretch = 1,
    double squash = 1,
  }) {
    if (opacity <= 0.004 || radius <= 0) {
      return;
    }
    final segments = _segmentsFor(radius * max(stretch, squash));
    final step = _maxSegments ~/ segments;
    if (!_reserve(1 + _discRings.length * segments, segments * 15)) {
      return;
    }
    final rgb = color.toARGB32() & 0x00FFFFFF;
    final ux = cos(angle), uy = sin(angle);
    final center = _vertex(x, y, _argb(rgb, opacity));
    var previousRing = -1;
    for (var ring = 0; ring < _discRings.length; ring++) {
      final r = radius * _discRings[ring];
      final ringColor = _argb(rgb, opacity * _discRingAlphas[ring]);
      final firstVertex = _vertexCount;
      for (var i = 0; i < segments; i++) {
        final lx = _unitCos[i * step] * r * stretch;
        final ly = _unitSin[i * step] * r * squash;
        _vertex(x + lx * ux - ly * uy, y + lx * uy + ly * ux, ringColor);
      }
      for (var i = 0; i < segments; i++) {
        final a = firstVertex + i;
        final b = firstVertex + (i + 1) % segments;
        if (previousRing < 0) {
          _triangle(center, a, b);
        } else {
          final pa = previousRing + i;
          final pb = previousRing + (i + 1) % segments;
          _triangle(pa, a, b);
          _triangle(pa, b, pb);
        }
      }
      previousRing = firstVertex;
    }
  }

  /// A soft ring. When [facing] is set, only the side of the ring that looks
  /// towards that angle is visible, fading out around [halfSpread] radians
  /// away from it.
  void addRing(
    double x,
    double y,
    double radius,
    double width,
    Color color,
    double opacity, {
    double? facing,
    double halfSpread = pi / 2,
  }) {
    if (opacity <= 0.004 || radius <= 0 || width <= 0) {
      return;
    }
    final segments = _segmentsFor(radius);
    final step = _maxSegments ~/ segments;
    if (!_reserve(3 * (segments + 1), segments * 12)) {
      return;
    }
    final rgb = color.toARGB32() & 0x00FFFFFF;
    final transparent = _argb(rgb, 0);
    final inner = max(0.0, radius - width / 2);
    final outer = radius + width / 2;
    final fadeFrom = cos(min(pi, halfSpread + 0.6));
    final fadeTo = cos(max(0.0, halfSpread - 0.6));
    final facingCos = facing == null ? 0.0 : cos(facing);
    final facingSin = facing == null ? 0.0 : sin(facing);
    final first = _vertexCount;
    for (var i = 0; i <= segments; i++) {
      final c = _unitCos[i * step], s = _unitSin[i * step];
      var alpha = opacity;
      if (facing != null) {
        final towards = c * facingCos + s * facingSin;
        alpha *= _smoothStep(fadeFrom, fadeTo, towards);
      }
      _vertex(x + c * inner, y + s * inner, transparent);
      _vertex(x + c * radius, y + s * radius, _argb(rgb, alpha));
      _vertex(x + c * outer, y + s * outer, transparent);
    }
    for (var i = 0; i < segments; i++) {
      final a = first + i * 3;
      final b = a + 3;
      _triangle(a, b, a + 1);
      _triangle(a + 1, b, b + 1);
      _triangle(a + 1, b + 1, a + 2);
      _triangle(a + 2, b + 1, b + 2);
    }
  }

  /// A spark: a thin streak from its bright [headColor] head to a tail that
  /// fades out into [tailColor].
  void addStreak(
    double headX,
    double headY,
    double tailX,
    double tailY,
    double width,
    Color headColor,
    Color tailColor,
    double opacity,
  ) {
    if (opacity <= 0.004) {
      return;
    }
    final dx = headX - tailX, dy = headY - tailY;
    final length = sqrt(dx * dx + dy * dy);
    if (length < 0.001) {
      return;
    }
    if (!_reserve(5, 12)) {
      return;
    }
    // Unit direction and normal
    final ux = dx / length, uy = dy / length;
    final half = width / 2;
    // The widest point is close to the head
    final bodyX = headX - dx * 0.22, bodyY = headY - dy * 0.22;
    final headRgb = headColor.toARGB32() & 0x00FFFFFF;
    final tailRgb = tailColor.toARGB32() & 0x00FFFFFF;
    final head = _vertex(
      headX + ux * half,
      headY + uy * half,
      _argb(headRgb, opacity * 0.6),
    );
    final body = _vertex(bodyX, bodyY, _argb(headRgb, opacity));
    final left = _vertex(
      bodyX - uy * half,
      bodyY + ux * half,
      _argb(tailRgb, opacity * 0.35),
    );
    final right = _vertex(
      bodyX + uy * half,
      bodyY - ux * half,
      _argb(tailRgb, opacity * 0.35),
    );
    final tail = _vertex(tailX, tailY, _argb(tailRgb, 0));
    _triangle(head, left, body);
    _triangle(head, body, right);
    _triangle(body, left, tail);
    _triangle(body, tail, right);
  }

  /// A soft comet tail from ([headX], [headY]) going [length] back against
  /// the direction ([dirX], [dirY]) (a unit vector). It is [width] wide at
  /// the head, thins out towards the end, fades from [headColor] into
  /// [tailColor], and its edges fade out so it has no hard outline.
  ///
  /// With [wave] it wiggles sideways like a flame, more towards the end;
  /// move [wavePhase] over time to make it flow.
  void addTail(
    double headX,
    double headY,
    double dirX,
    double dirY,
    double length,
    double width,
    Color headColor,
    Color tailColor,
    double opacity, {
    double wave = 0,
    double wavePhase = 0,
    int segments = 8,
  }) {
    if (opacity <= 0.004 || length <= 0 || width <= 0) {
      return;
    }
    const capPoints = 7;
    if (!_reserve(3 * (segments + 1) + capPoints, segments * 12 + 24)) {
      return;
    }
    final headRgb = headColor.toARGB32() & 0x00FFFFFF;
    final tailRgb = tailColor.toARGB32() & 0x00FFFFFF;
    // The normal
    final nx = -dirY, ny = dirX;
    final first = _vertexCount;
    for (var i = 0; i <= segments; i++) {
      final s = i / segments;
      final half = width / 2 * pow(1 - s, 0.8);
      final sway = wave == 0 ? 0.0 : sin(wavePhase - s * 5.5) * wave * s;
      final cx = headX - dirX * length * s + nx * sway;
      final cy = headY - dirY * length * s + ny * sway;
      final rgb = _lerpRgb(headRgb, tailRgb, s);
      final alpha = opacity * pow(1 - s, 1.4);
      _vertex(cx - nx * half, cy - ny * half, _argb(rgb, 0));
      _vertex(cx, cy, _argb(rgb, alpha));
      _vertex(cx + nx * half, cy + ny * half, _argb(rgb, 0));
    }
    for (var i = 0; i < segments; i++) {
      final a = first + i * 3;
      final b = a + 3;
      _triangle(a, b, a + 1);
      _triangle(a + 1, b, b + 1);
      _triangle(a + 1, b + 1, a + 2);
      _triangle(a + 2, b + 1, b + 2);
    }
    // A round cap in front of the head, so the tail doesn't end in a line
    final half = width / 2;
    final angle = atan2(ny, nx);
    var previous = first;
    for (var i = 1; i <= capPoints; i++) {
      final a = angle + pi + pi * i / (capPoints + 1);
      final point = _vertex(
        headX + cos(a) * half,
        headY + sin(a) * half,
        _argb(headRgb, 0),
      );
      _triangle(first + 1, previous, point);
      previous = point;
    }
    _triangle(first + 1, previous, first + 2);
  }

  /// A soft band that follows an arc around ([x], [y]). [radiusAt] and
  /// [intensityAt] are asked for each of the [segments] + 1 angles along the
  /// arc, so the band can bend and glow more in some places.
  void addArcBand(
    double x,
    double y,
    double startAngle,
    double sweep,
    int segments,
    double width,
    Color color,
    double Function(double angle) radiusAt,
    double Function(double angle) intensityAt,
  ) {
    if (!_reserve(3 * (segments + 1), segments * 12)) {
      return;
    }
    final rgb = color.toARGB32() & 0x00FFFFFF;
    final transparent = _argb(rgb, 0);
    final half = width / 2;
    final first = _vertexCount;
    for (var i = 0; i <= segments; i++) {
      final angle = startAngle + sweep * i / segments;
      final c = cos(angle), s = sin(angle);
      final r = radiusAt(angle);
      final alpha = intensityAt(angle);
      _vertex(x + c * (r - half), y + s * (r - half), transparent);
      _vertex(x + c * r, y + s * r, _argb(rgb, alpha));
      _vertex(x + c * (r + half), y + s * (r + half), transparent);
    }
    for (var i = 0; i < segments; i++) {
      final a = first + i * 3;
      final b = a + 3;
      _triangle(a, b, a + 1);
      _triangle(a + 1, b, b + 1);
      _triangle(a + 1, b + 1, a + 2);
      _triangle(a + 2, b + 1, b + 2);
    }
  }

  void render(Canvas canvas) {
    if (_indexCount == 0) {
      return;
    }
    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.sublistView(_positions, 0, _vertexCount * 2),
      colors: Int32List.sublistView(_colors, 0, _vertexCount),
      indices: Uint16List.sublistView(_indices, 0, _indexCount),
    );
    // BlendMode.dst: use the vertex colors and ignore the paint's color
    canvas.drawVertices(vertices, BlendMode.dst, _paint);
    vertices.dispose();
  }

  static int _argb(int rgb, double opacity) =>
      ((opacity.clamp(0.0, 1.0) * 255).round() << 24) | rgb;

  static int _lerpRgb(int from, int to, double t) {
    int channel(int shift) {
      final a = (from >> shift) & 0xFF, b = (to >> shift) & 0xFF;
      return (a + (b - a) * t).round() << shift;
    }

    return channel(16) | channel(8) | channel(0);
  }

  static double _smoothStep(double from, double to, double value) {
    final t = ((value - from) / (to - from)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  int _vertex(double x, double y, int color) {
    final index = _vertexCount++;
    _positions[index * 2] = x;
    _positions[index * 2 + 1] = y;
    _colors[index] = color;
    return index;
  }

  void _triangle(int a, int b, int c) {
    _indices[_indexCount++] = a;
    _indices[_indexCount++] = b;
    _indices[_indexCount++] = c;
  }

  /// Makes room for [vertices] more vertices and [indices] more indices.
  /// Returns false when the shape doesn't fit in 16-bit indices anymore.
  bool _reserve(int vertices, int indices) {
    final neededVertices = _vertexCount + vertices;
    if (neededVertices > _maxVertices) {
      return false;
    }
    if (neededVertices > _colors.length) {
      final capacity = max(neededVertices, _colors.length * 2);
      _positions = Float32List(capacity * 2)
        ..setRange(0, _vertexCount * 2, _positions);
      _colors = Int32List(capacity)..setRange(0, _vertexCount, _colors);
    }
    final neededIndices = _indexCount + indices;
    if (neededIndices > _indices.length) {
      final capacity = max(neededIndices, _indices.length * 2);
      _indices = Uint16List(capacity)..setRange(0, _indexCount, _indices);
    }
    return true;
  }
}
