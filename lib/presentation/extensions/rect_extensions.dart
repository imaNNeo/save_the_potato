import 'dart:math';
import 'package:flame/extensions.dart';

extension RectExtensions on Rect {
  Vector2 randomPointExcludeRect(Rect insideRect, [Random? random]) {
    random ??= Random();
    final x = random.nextDouble() * width + left;
    final y = random.nextDouble() * height + top;

    if (insideRect.contains(Offset(x, y))) {
      return randomPointExcludeRect(insideRect, random);
    }

    return Vector2(x, y);
  }

  Rect expandBy(double width, double height) => Rect.fromCenter(
        center: center,
        width: this.width + width,
        height: this.height + height,
      );
}
