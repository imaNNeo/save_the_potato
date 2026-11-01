import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/rhythm/orb_sides.dart';

/// Signed distance between two angles, in -pi..pi
double gap(double a, double b) => atan2(sin(a - b), cos(a - b));

void main() {
  test('one shield spot blocks every fire and ice orb near the same time', () {
    for (var seed = 0; seed < 20; seed++) {
      final sides = OrbSides(random: Random(seed))..reset();
      for (var land = 2.0; land < 300; land += 0.25) {
        final difficulty = min(1.0, land / 300);
        final type = (land * 4).round().isEven ? OrbType.fire : OrbType.ice;
        final angle = sides.angleFor(type, land, difficulty);
        final fireSide = sides.fireSideAt(land, difficulty);
        final shieldNeeded = type == OrbType.fire ? angle : angle + pi;
        // The shield covers 45° each way; the groups stay inside that
        expect(gap(shieldNeeded, fireSide).abs(), lessThan(pi / 4));
      }
    }
  });

  test('the sides turn gently and travel around the arena', () {
    final sides = OrbSides(random: Random(7))..reset();
    var visitedLeft = false;
    var visitedRight = false;
    var previous = sides.fireSideAt(0, 1);
    for (var t = 0.05; t < 120; t += 0.05) {
      final side = sides.fireSideAt(t, 1);
      // Never faster than a gentle turn (the shield turns ~324°/s)
      expect((side - previous).abs() / 0.05, lessThan(pi / 3));
      previous = side;
      final x = cos(side);
      visitedLeft |= x < -0.9;
      visitedRight |= x > 0.9;
    }
    expect(visitedLeft && visitedRight, isTrue);
  });
}
