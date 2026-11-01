import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';

/// Draws the rifts and blurs the game uses for the first few frames,
/// clipped to a single pixel so nobody sees it. The GPU compiles a shader
/// the first time it sees an effect, which drops frames; this makes that
/// happen on the home screen instead of when the first rift or game over
/// shows up mid-game.
///
/// It draws straight on the game canvas (not into a layer), because the GPU
/// keeps separate shaders for layers and the screen.
class GameShaderWarmUp extends Component {
  GameShaderWarmUp() : super(priority: -100);

  int _frames = 0;

  @override
  void render(Canvas canvas) {
    canvas
      ..save()
      ..clipRect(const Rect.fromLTWH(0, 0, 1, 1));
    for (final type in OrbType.values) {
      for (final (form, closing) in [(0.3, 0.0), (0.9, 0.0), (1.0, 0.5)]) {
        RingRift.paint(
          canvas,
          type: type,
          spawnAngle: 0,
          form: form,
          closing: closing,
          time: form * 3,
        );
      }
    }
    // The blur shader changes with the blur's size on screen, which changes
    // with the camera zoom, so warm up the whole range
    final line = Path()
      ..moveTo(-6, 0.5)
      ..lineTo(6, 0.5);
    for (var sigma = 0.25; sigma <= 8; sigma += 0.25) {
      canvas.drawPath(
        line,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }
    // The game over screen blurs what is behind it, growing to 16
    for (var sigma = 0.5; sigma <= 16; sigma += 0.5) {
      canvas
        ..saveLayer(
          const Rect.fromLTWH(0, 0, 1, 1),
          Paint()
            ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        )
        ..drawRect(
          const Rect.fromLTWH(-2, -2, 5, 5),
          Paint()..color = const Color(0xFF000000),
        )
        ..restore();
    }
    canvas.restore();
    if (++_frames >= 3) {
      removeFromParent();
    }
  }
}
