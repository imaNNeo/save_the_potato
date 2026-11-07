import 'dart:math';

import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/game_constants.dart';

/// Shows what the splash is still loading as a little music meter under
/// the potato: its bars light up from hot to cold and jump with the beat the
/// potato grooves to.
class SplashLoadingPainter extends CustomPainter {
  SplashLoadingPainter({
    required this.center,
    required this.potatoSize,
    required this.progress,
    required this.opacity,
    required this.beat,
  });

  final Offset center;
  final double potatoSize;

  /// 0..1
  final double progress;
  final double opacity;

  /// 1 right on a beat, falling to 0 just before the next one
  final double beat;

  static const _fire = GameConstants.redColors;
  static const _ice = GameConstants.blueColors;

  /// Hot on the left, cold on the right, like the title
  static Color _colorAt(double x) => x < 0.5
      ? Color.lerp(_fire[0], Colors.white, x * 2)!
      : Color.lerp(Colors.white, _ice[0], x * 2 - 1)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    _paintEqualizer(canvas);
  }

  /// Under the potato, where its shadow would be
  double get _belowPotato => center.dy + potatoSize * 0.75 + 28;

  void _paintEqualizer(Canvas canvas) {
    const count = 9;
    const barWidth = 7.0;
    const gap = 6.0;
    const maxHeight = 34.0;
    const minHeight = barWidth;
    const total = count * barWidth + (count - 1) * gap;
    final baseY = _belowPotato + maxHeight / 2;
    final left = center.dx - total / 2;
    for (var i = 0; i < count; i++) {
      final x = i / (count - 1);
      // How lit this bar is
      final lit = (progress * count - i).clamp(0.0, 1.0);
      // Each bar jumps on the beat by its own amount, like a music meter
      final bounce = 0.35 + 0.65 * (0.5 + 0.5 * sin(i * 2.1 + 1.3));
      final height =
          minHeight +
          (maxHeight - minHeight) * lit * (0.3 + 0.7 * beat * bounce);
      final rect = Rect.fromLTWH(
        left + i * (barWidth + gap),
        baseY - height,
        barWidth,
        height,
      );
      final color = Color.lerp(
        Colors.white.withValues(alpha: 0.12),
        _colorAt(x),
        lit,
      )!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(barWidth / 2)),
        Paint()..color = color.withValues(alpha: color.a * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SplashLoadingPainter old) => true;
}
