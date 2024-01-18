import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class VictoryLines extends StatefulWidget {
  const VictoryLines({
    super.key,
    this.animated = true,
  });

  final bool animated;

  @override
  State<VictoryLines> createState() => _VictoryLinesState();
}

class _VictoryLinesState extends State<VictoryLines>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      if (!widget.animated) {
        return CustomPaint(
          size: Size(width, height),
          painter: _VictoryLinesPainter(
            startingPoint: 0,
          ),
        );
      }
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            size: Size(width, height),
            painter: _VictoryLinesPainter(
              startingPoint: _animationController.value * pi * 2,
            ),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _VictoryLinesPainter extends CustomPainter {
  final double startingPoint;
  final Color color1 = Colors.white10;
  final Color color2 = Colors.white24;

  _VictoryLinesPainter({
    this.startingPoint = 0.0,
  });

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    int linesCount = 16;
    double step = (pi * 2) / linesCount;
    final center = (size / 2).toOffset();
    final longestSize = max(size.width, size.height);
    for (int i = 0; i < linesCount; i++) {
      double degree = startingPoint + (step * i);
      Path path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + longestSize * cos(degree),
          center.dy + longestSize * sin(degree),
        )
        ..lineTo(
          center.dx + longestSize * cos(degree + step),
          center.dy + longestSize * sin(degree + step),
        );
      canvas.drawPath(
        path,
        _paint
          ..color = i.isEven ? color1 : color2
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VictoryLinesPainter oldDelegate) =>
      oldDelegate.startingPoint != startingPoint;
}
