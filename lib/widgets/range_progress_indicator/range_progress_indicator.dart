import 'package:flutter/material.dart';
import 'package:save_the_potato/models/double_range.dart';

class RangeProgressIndicator extends StatelessWidget {
  const RangeProgressIndicator({
    super.key,
    required this.min,
    required this.max,
    required this.range,
  });

  final double min;
  final double max;
  final DoubleRange range;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, 20),
        painter: _RangeProgressIndicatorPainter(
          range: range,
          min: min,
          max: max,
          baseColor: Theme.of(context).colorScheme.primary.withOpacity(0.24),
          rangeColor: Theme.of(context).colorScheme.primary,
        ),
      );
    });
  }
}

class _RangeProgressIndicatorPainter extends CustomPainter {
  _RangeProgressIndicatorPainter({
    required this.min,
    required this.max,
    required this.range,
    required this.baseColor,
    required this.rangeColor,
  });

  final double min;
  final double max;
  final DoubleRange range;
  final Color baseColor;
  final Color rangeColor;

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 6.0;
    const indicatorThickness = 3.0;
    const indicatorHeight = 14.0;
    canvas.drawRect(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width,
        height: trackHeight,
      ),
      Paint()..color = baseColor,
    );

    final double left = ((range.min - min) / (max - min)) * size.width;
    final double right = ((range.max - min) / (max - min)) * size.width;

    // Draw track
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset((left + right) / 2, size.height / 2),
        width: right - left,
        height: trackHeight,
      ),
      Paint()..color = rangeColor,
    );

    // Draw left indicator
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(left, size.height / 2),
        width: indicatorThickness,
        height: indicatorHeight,
      ),
      Paint()..color = rangeColor,
    );

    // Draw right indicator
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(right, size.height / 2),
        width: indicatorThickness,
        height: indicatorHeight,
      ),
      Paint()..color = rangeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RangeProgressIndicatorPainter oldDelegate) =>
      oldDelegate.range != range &&
      oldDelegate.min != min &&
      oldDelegate.max != max &&
      oldDelegate.baseColor != baseColor &&
      oldDelegate.rangeColor != rangeColor;
}
