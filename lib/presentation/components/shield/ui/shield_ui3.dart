import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/shield/shield.dart';
import 'package:save_the_potato/presentation/potato_game.dart';
import 'dart:ui' as ui;

class _Particle {
  final int index;
  final Offset topLeft;
  final Offset size;

  Offset get center => topLeft + size / 2;

  const _Particle(this.index, this.topLeft, this.size);
}

const _particles = [
  _Particle(0, Offset(0, 0), Offset(90, 29)),
  _Particle(0, Offset(90, 0), Offset(163, 27)),
  _Particle(0, Offset(253, 0), Offset(219, 54)),
  _Particle(0, Offset(427, 0), Offset(288, 83)),
  _Particle(0, Offset(427, 0), Offset(288, 83)),
  _Particle(0, Offset(0, 83), Offset(320, 70)),
  _Particle(0, Offset(320, 83), Offset(233, 75)),
  _Particle(0, Offset(553, 83), Offset(304, 95)),
  _Particle(0, Offset(0, 178), Offset(410, 116)),
  _Particle(0, Offset(410, 178), Offset(64, 64)),
  _Particle(0, Offset(474, 178), Offset(64, 64)),
  _Particle(0, Offset(538, 178), Offset(64, 64)),
  _Particle(0, Offset(602, 178), Offset(64, 64)),
];

class ShieldUiStyle3 extends PositionComponent
    with ParentIsA<Shield>, HasGameRef<PotatoGame> {
  late ui.Image imageAtlas;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    imageAtlas = await gameRef.images.load('flame/all.png');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final transforms = List.generate(4, (index) => Matrix4.identity());

    Paint paint = Paint();
    canvas.drawAtlas(
      imageAtlas,
      <RSTransform>[
        for (final _Particle particle in _particles)
          RSTransform.fromComponents(
            rotation: 0.0,
            scale: 0.3,
            // Center of the sprite relative to its rect
            anchorX: particle.size.dx / 2,
            anchorY: particle.size.dy / 2,
            // Location at which to draw the center of the sprite
            translateX: particle.center.dx,
            translateY: particle.center.dy,
          ),
      ],
      <Rect>[
        for (final _Particle particle in _particles)
          Rect.fromLTWH(
            particle.topLeft.dx,
            particle.topLeft.dy,
            particle.size.dx,
            particle.size.dy,
          ),
      ],
      _particles.map((_) => Colors.red).toList(),
      BlendMode.dstIn,
      null,
      paint,
    );
  }
}
