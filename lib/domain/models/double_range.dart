import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';

class DoubleRange with EquatableMixin {
  final double min;
  final double max;

  const DoubleRange({
    required this.min,
    required this.max,
  });

  double random() => min + (max - min) * Random().nextDouble();

  static DoubleRange lerp(DoubleRange a, DoubleRange b, double t) =>
      DoubleRange(
        min: lerpDouble(a.min, b.min, t)!,
        max: lerpDouble(a.max, b.max, t)!,
      );

  double lerpValue(double t) => lerpDouble(min, max, t)!;

  String get simpleFormat => '($min, $max)';

  String get simpleFormatInt => '(${min.toInt()}, ${max.toInt()})';

  @override
  List<Object?> get props => [
        min,
        max,
      ];
}
