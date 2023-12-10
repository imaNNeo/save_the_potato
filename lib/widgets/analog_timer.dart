import 'dart:math';

import 'package:flutter/material.dart';
import 'package:save_the_potato/game_configs.dart';

class AnalogTimer extends StatelessWidget {
  const AnalogTimer({
    super.key,
    required this.time,
  });

  final double time;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _AnalogTimerPainter(time),
      ),
    );
  }
}

class _AnalogTimerPainter extends CustomPainter {
  final double time;

  double normalTickLength = 0.12;
  double quarterTickLength = 0.15;
  double tickWidthRatio = 0.02;
  double quarterTickWidthRatio = 0.03;
  double tickSpaceRatio = 6;
  double handWidthRatio = 0.02;

  _AnalogTimerPainter(this.time);

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
    final secondsHandDegree = (pi * 2) * (time / 60) - (pi / 2);
    final lineStrokeWidth = handWidthRatio * radius;
    canvas.drawLine(
      center,
      polarToCartesian(secondsHandDegree, radius - lineStrokeWidth / 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = lineStrokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalogTimerPainter oldDelegate) =>
      oldDelegate.time != time;
}
