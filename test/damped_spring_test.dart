import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/components/damped_spring.dart';

void main() {
  test('kicked out to 1, swings back a little and rests', () {
    final spring = DampedSpring(frequency: 2 * pi * 7, damping: 0.45);
    final samples = [for (var i = 0; i <= 600; i++) spring.at(i / 1000)];

    expect(samples.first, 0);
    expect(samples.reduce(max), closeTo(1, 0.001));
    final lowest = samples.reduce(min);
    expect(lowest, lessThan(0));
    expect(lowest, greaterThan(-0.5));
    expect(spring.at(0.6).abs(), lessThan(0.01));
  });
}
