import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';

class SpriteParticle {
  late Sprite sprite;
  late Color color;
  late double lifespan;
  double elapsed = 0;
  final position = Vector2.zero();
  final acceleration = Vector2.zero();
  final speed = Vector2.zero();

  /// How quickly [speed] fades away (per second), 0 keeps it
  double drag = 0.0;

  /// Added to [drawRotation] every second
  double spin = 0.0;

  /// Set by the batch's prepare callback right before drawing
  double drawScale = 1.0;
  double drawRotation = 0.0;
  double drawOpacity = 1.0;

  /// Free slots for the owner to tell particle kinds apart and keep their size
  int kind = 0;
  double baseScale = 1.0;

  double get progress => min(1.0, elapsed / lifespan);
}

/// Called for each particle right before drawing. Sets [SpriteParticle]'s
/// draw fields and returns false to skip the particle.
typedef SpriteParticlePrepare = bool Function(SpriteParticle particle);

/// Keeps many short-lived sprite particles as plain data and draws them with
/// one [Canvas.drawRawAtlas] call per image.
///
/// Each particle is drawn centered on its position, tinted with its color
/// (same result as `ColorFilter.mode(color, BlendMode.srcIn)`). This is much cheaper
/// than a component, a canvas transform and a draw call per particle.
class SpriteParticleBatch {
  final _alive = <SpriteParticle>[];
  final _free = <SpriteParticle>[];
  final _paint = Paint();
  final _images = <Image>[];

  var _transforms = Float32List(0);
  var _rects = Float32List(0);
  var _colors = Int32List(0);

  int get length => _alive.length;

  /// The particles alive right now, to move them all at once
  Iterable<SpriteParticle> get particles => _alive;

  /// Returns a reset particle that is already alive; set its fields.
  SpriteParticle spawn({required Sprite sprite, required double lifespan}) {
    final particle = _free.isNotEmpty ? _free.removeLast() : SpriteParticle();
    particle
      ..sprite = sprite
      ..lifespan = lifespan
      ..elapsed = 0
      ..drag = 0
      ..spin = 0
      ..drawRotation = 0
      ..kind = 0
      ..baseScale = 1;
    particle.position.setZero();
    particle.acceleration.setZero();
    particle.speed.setZero();
    _alive.add(particle);
    return particle;
  }

  void update(double dt) {
    for (var i = _alive.length - 1; i >= 0; i--) {
      final p = _alive[i];
      p.elapsed += dt;
      if (p.elapsed >= p.lifespan) {
        _alive[i] = _alive.last;
        _alive.removeLast();
        _free.add(p);
        continue;
      }
      p.position.addScaled(p.acceleration, dt);
      p.speed.addScaled(p.acceleration, dt);
      if (p.drag != 0) {
        p.speed.scale(exp(-p.drag * dt));
      }
      p.position
        ..addScaled(p.speed, dt)
        ..addScaled(p.acceleration, -dt * dt * 0.5);
      p.drawRotation += p.spin * dt;
    }
  }

  void clear() {
    _free.addAll(_alive);
    _alive.clear();
  }

  void render(Canvas canvas, SpriteParticlePrepare prepare) {
    if (_alive.isEmpty) {
      return;
    }
    _ensureCapacity(_alive.length);

    _images.clear();
    for (final p in _alive) {
      final image = p.sprite.image;
      if (!_images.contains(image)) {
        _images.add(image);
      }
    }

    for (final image in _images) {
      var count = 0;
      for (final p in _alive) {
        if (p.sprite.image != image || !prepare(p)) {
          continue;
        }
        final src = p.sprite.src;
        final scos = p.drawScale * cos(p.drawRotation);
        final ssin = p.drawScale * sin(p.drawRotation);
        final anchorX = src.width / 2;
        final anchorY = src.height / 2;
        final i4 = count * 4;
        _transforms[i4] = scos;
        _transforms[i4 + 1] = ssin;
        _transforms[i4 + 2] = p.position.x - scos * anchorX + ssin * anchorY;
        _transforms[i4 + 3] = p.position.y - ssin * anchorX - scos * anchorY;
        _rects[i4] = src.left;
        _rects[i4 + 1] = src.top;
        _rects[i4 + 2] = src.right;
        _rects[i4 + 3] = src.bottom;
        _colors[count] = p.color.withValues(alpha: p.drawOpacity).toARGB32();
        count++;
      }
      if (count == 0) {
        continue;
      }
      canvas.drawRawAtlas(
        image,
        Float32List.sublistView(_transforms, 0, count * 4),
        Float32List.sublistView(_rects, 0, count * 4),
        Int32List.sublistView(_colors, 0, count),
        // In drawAtlas the sprite is the source and the color the destination
        BlendMode.dstIn,
        null,
        _paint,
      );
    }
  }

  void _ensureCapacity(int count) {
    if (_colors.length >= count) {
      return;
    }
    final capacity = max(count, _colors.length * 2);
    _transforms = Float32List(capacity * 4);
    _rects = Float32List(capacity * 4);
    _colors = Int32List(capacity);
  }
}
