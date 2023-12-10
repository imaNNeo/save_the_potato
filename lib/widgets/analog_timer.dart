import 'dart:math';

import 'package:flutter/material.dart';
import 'package:save_the_potato/game_configs.dart';

class AnalogTimer extends StatelessWidget {
  const AnalogTimer({
    super.key,
    required this.time,
    required this.isGameOverStyle,
    required this.size,
  });

  final double time;
  final bool isGameOverStyle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
           Center(
              child: Icon(
                isGameOverStyle ? Icons.star_border : Icons.safety_check,
                color: Colors.white.withOpacity(isGameOverStyle ? 0.5 : 0.2),
                size: isGameOverStyle ? size * 0.5: size * 0.5,
              ),
            ),
          CustomPaint(
            painter: _AnalogTimerPainter(
              time,
              isGameOverStyle,
            ),
            size: Size(size, size),
          ),
        ],
      ),
    );
  }
}

class _AnalogTimerPainter extends CustomPainter {
  double normalTickLength = 0.12;
  double quarterTickLength = 0.15;
  double tickWidthRatio = 0.02;
  double quarterTickWidthRatio = 0.03;
  double tickSpaceRatio = 6;
  double handWidthRatio = 0.01;

  _AnalogTimerPainter(this.time, this.isGameOverStyle);

  final double time;
  final bool isGameOverStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    Offset polarToCartesian(double degree, double radius) =>
        center +
        Offset.fromDirection(
          degree,
          radius,
        );

    for (int minutes = 0; minutes <= time ~/ 60; minutes++) {
      for (int seconds = 0; seconds < 60; seconds++) {
        bool isQuarter = seconds % 15 == 0;
        final degree = (pi * 2) * (seconds / 60) - (pi / 2);
        final thisTurnRadius = radius -
            ((radius * quarterTickLength * minutes) +
                (minutes * tickSpaceRatio));
        final thickLength =
            (isQuarter ? quarterTickLength : normalTickLength) * thisTurnRadius;
        final fromOffset = polarToCartesian(
          degree,
          thisTurnRadius - thickLength,
        );
        final toOffset = polarToCartesian(
          degree,
          thisTurnRadius,
        );

        bool isPassed = seconds + minutes * 60 <= time;
        final color = isPassed
            ? seconds % 2 == 0
                ? GameConfigs.coldColors.last
                : GameConfigs.hotColors.first
            : Colors.white.withOpacity(isQuarter ? 0.3 : 0.1);
        final strokeWidth = isPassed
            ? (isQuarter
                ? quarterTickWidthRatio * radius
                : tickWidthRatio * radius)
            : tickWidthRatio * radius;
        canvas.drawLine(
          fromOffset,
          toOffset,
          Paint()
            ..color = color
            ..strokeWidth = strokeWidth,
        );
      }
    }

    if (!isGameOverStyle) {
      final secondsHandDegree = (pi * 2) * (time / 60) - (pi / 2);
      final lineStrokeWidth = handWidthRatio * radius;
      canvas.drawLine(
        center,
        polarToCartesian(secondsHandDegree, radius - lineStrokeWidth / 2),
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = lineStrokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnalogTimerPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.isGameOverStyle != isGameOverStyle;
}
