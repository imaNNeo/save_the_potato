import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/shield_steering.dart';

double _hold(ShieldSteering steering, double seconds, {double dt = 1 / 60}) {
  var turned = 0.0;
  for (var t = 0.0; t < seconds - 1e-9; t += dt) {
    turned += steering.update(dt);
  }
  return turned;
}

void main() {
  test('nothing held turns nothing', () {
    final steering = ShieldSteering();
    expect(steering.update(0.1), 0);
  });

  test('classic turns at full speed right away', () {
    final steering = ShieldSteering(style: ShieldSteeringStyle.classic)
      ..direction = 1;
    expect(
      _hold(steering, 0.1),
      closeTo(ShieldSteering.classicSpeed * 0.1, 1e-9),
    );
  });

  test('steady is slower than classic', () {
    final steering = ShieldSteering(style: ShieldSteeringStyle.steady)
      ..direction = -1;
    expect(
      _hold(steering, 0.5),
      closeTo(-ShieldSteering.steadySpeed * 0.5, 1e-9),
    );
    expect(ShieldSteering.steadySpeed, lessThan(ShieldSteering.classicSpeed));
  });

  group('ramp', () {
    test('a quick tap only nudges the shields', () {
      final steering = ShieldSteering(style: ShieldSteeringStyle.ramp)
        ..direction = 1;
      final turned = _hold(steering, 0.1);
      expect(turned, greaterThan(0));
      // Well under half of what the old controls turned
      expect(turned, lessThan(ShieldSteering.classicSpeed * 0.1 / 2));
      expect(turned, lessThan(pi / 12));
    });

    test('speeds up while held and stops at the cap', () {
      final steering = ShieldSteering(style: ShieldSteeringStyle.ramp)
        ..direction = 1;
      final early = steering.velocity;
      _hold(steering, 0.2);
      final middle = steering.velocity;
      _hold(steering, 1);
      final late = steering.velocity;
      expect(early, ShieldSteering.rampStartSpeed);
      expect(middle, greaterThan(early));
      expect(late, ShieldSteering.rampMaxSpeed);
    });

    test('frame rate does not change how far it turns', () {
      final at60 = ShieldSteering(style: ShieldSteeringStyle.ramp)
        ..direction = 1;
      final at144 = ShieldSteering(style: ShieldSteeringStyle.ramp)
        ..direction = 1;
      expect(
        _hold(at60, 1, dt: 1 / 60),
        closeTo(_hold(at144, 1, dt: 1 / 144), 0.03),
      );
    });

    test('switching side starts the ramp over', () {
      final steering = ShieldSteering(style: ShieldSteeringStyle.ramp)
        ..direction = 1;
      _hold(steering, 1);
      steering.direction = -1;
      expect(steering.velocity, -ShieldSteering.rampStartSpeed);
    });
  });

  test('styles parse from their names', () {
    expect(ShieldSteeringStyle.tryParse('steady'), ShieldSteeringStyle.steady);
    expect(ShieldSteeringStyle.tryParse('nope'), isNull);
    expect(ShieldSteeringStyle.tryParse(null), isNull);
  });
}
