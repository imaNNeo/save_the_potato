import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/life_meter.dart';

void main() {
  test('3 misses in a row from the start end the game', () {
    var life = LifeMeter.start;
    life = LifeMeter.afterMiss(life);
    expect(life, greaterThan(0));
    life = LifeMeter.afterMiss(life);
    expect(life, greaterThan(0));
    expect(LifeMeter.stageOf(life), 0);
    life = LifeMeter.afterMiss(life);
    expect(life, 0);
  });

  test('4 misses in a row from a full bar end the game', () {
    var life = 1.0;
    for (var i = 0; i < 3; i++) {
      life = LifeMeter.afterMiss(life);
      expect(life, greaterThan(0));
    }
    expect(LifeMeter.afterMiss(life), 0);
  });

  test('blocks fill the bar up to full and through every stage', () {
    var life = LifeMeter.start;
    final stages = <int>{};
    for (var i = 0; i < 40; i++) {
      life = LifeMeter.afterBlock(life);
      stages.add(LifeMeter.stageOf(life));
    }
    expect(life, 1.0);
    expect(stages, {2, 3, 4});
    expect(LifeMeter.stageOf(1.0), LifeMeter.lastStage);
  });

  test('stages', () {
    expect(LifeMeter.stageOf(0.1), 0);
    expect(LifeMeter.stageOf(0.2), 1);
    expect(LifeMeter.stageOf(0.49), 1);
    expect(LifeMeter.stageOf(0.5), 2);
    expect(LifeMeter.stageOf(0.5 + 15 * LifeMeter.perBlock), 3);
  });
}
