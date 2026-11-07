import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/health_mood.dart';
import 'package:save_the_potato/domain/life_meter.dart';

void main() {
  test('starts normal', () {
    expect(HealthMood.of(LifeMeter.start), HealthMood.normal);
  });

  test('worried exactly when the next miss ends the run', () {
    expect(HealthMood.of(LifeMeter.danger - 0.01), HealthMood.worried);
    expect(HealthMood.of(LifeMeter.danger), HealthMood.normal);
    expect(
      HealthMood.of(LifeMeter.danger - 0.01, current: HealthMood.calm),
      HealthMood.worried,
    );
  });

  test('calm with plenty of life, with a little room before it leaves', () {
    expect(HealthMood.of(0.69), HealthMood.normal);
    expect(HealthMood.of(0.7), HealthMood.calm);
    expect(HealthMood.of(0.68, current: HealthMood.calm), HealthMood.calm);
    expect(HealthMood.of(0.65, current: HealthMood.calm), HealthMood.normal);
  });

  test('ten blocks from the start make it calm, one miss takes it away', () {
    var life = LifeMeter.start;
    for (var i = 0; i < 10; i++) {
      life = LifeMeter.afterBlock(life);
    }
    expect(HealthMood.of(life), HealthMood.calm);
    expect(
      HealthMood.of(LifeMeter.afterMiss(life), current: HealthMood.calm),
      HealthMood.normal,
    );
  });
}
