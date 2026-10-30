import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/background_reactions.dart';

void main() {
  void update(BackgroundReactions reactions, double dt, {bool multi = false}) {
    reactions.update(
      dt,
      heat: 0,
      power: 0,
      multiOrbWave: multi,
      kickX: 0,
      kickY: 0,
    );
  }

  test('a block sends a wave out that fades away', () {
    final reactions = BackgroundReactions();
    reactions.block(color: const Color(0xFFFF0000), angle: 0);
    final wave = reactions.waves.firstWhere((wave) => wave.isActive);

    update(reactions, 0.1);
    final radius = wave.radius;
    final intensity = wave.intensity;
    expect(intensity, greaterThan(0));

    update(reactions, 0.2);
    expect(wave.radius, greaterThan(radius));
    expect(wave.intensity, lessThan(intensity));

    update(reactions, 2);
    expect(wave.isActive, isFalse);
    expect(wave.intensity, 0);
  });

  test('more waves than slots replace the oldest one', () {
    final reactions = BackgroundReactions();
    for (var i = 0; i < BackgroundReactions.maxWaves; i++) {
      reactions.block(color: const Color(0xFF0000FF), angle: 0);
      update(reactions, 0.05);
    }
    final oldest = reactions.waves.reduce((a, b) => a.age > b.age ? a : b);
    reactions.milestone();
    expect(oldest.age, 0);
    expect(
      reactions.waves.where((wave) => wave.isActive).length,
      BackgroundReactions.maxWaves,
    );
  });

  test('getting hit flashes and shakes, then calms down', () {
    final reactions = BackgroundReactions();
    reactions.potatoHit(1);
    update(reactions, 0.016);
    expect(reactions.hit, greaterThan(0.9));
    for (var i = 0; i < 300; i++) {
      update(reactions, 0.016);
    }
    expect(reactions.hit, lessThan(0.01));
    expect(reactions.shakeX.abs(), lessThan(0.01));
  });

  test('gets tense only during a multi orb wave, in the chosen style', () {
    final reactions = BackgroundReactions();
    final style = BackgroundReactions.tenseStyle;
    addTearDown(() => BackgroundReactions.tenseStyle = style);

    BackgroundReactions.tenseStyle = TenseStyle.warpAndRedEdges;
    for (var i = 0; i < 120; i++) {
      update(reactions, 0.016, multi: true);
    }
    expect(reactions.tension, greaterThan(0.9));
    expect(reactions.warp, greaterThan(0.9));
    expect(reactions.redEdges, greaterThan(0));
    expect(reactions.speedLines, 0);
    expect(reactions.speedBoost, greaterThan(3));
    expect(reactions.stretch, greaterThan(0.5));

    BackgroundReactions.tenseStyle = TenseStyle.speedLines;
    expect(reactions.warp, 0);
    expect(reactions.redEdges, 0);
    expect(reactions.speedLines, greaterThan(0.9));

    for (var i = 0; i < 600; i++) {
      update(reactions, 0.016);
    }
    expect(reactions.tension, lessThan(0.01));
    expect(reactions.speedLines, lessThan(0.01));
  });

  test('the red edges pulse like a heartbeat', () {
    final reactions = BackgroundReactions();
    final style = BackgroundReactions.tenseStyle;
    addTearDown(() => BackgroundReactions.tenseStyle = style);
    BackgroundReactions.tenseStyle = TenseStyle.redEdges;

    final values = <double>[];
    for (var i = 0; i < 300; i++) {
      update(reactions, 0.016, multi: true);
      values.add(reactions.redEdges);
    }
    final last = values.sublist(200);
    expect(last.reduce(max) - last.reduce(min), greaterThan(0.2));
  });

  test('stops notifying once everything has calmed down', () {
    final reactions = BackgroundReactions();
    var notified = 0;
    reactions.addListener(() => notified++);
    update(reactions, 0.016);
    expect(notified, 0);

    reactions.block(color: const Color(0xFFFF0000), angle: 0);
    update(reactions, 0.016);
    expect(notified, 1);

    for (var i = 0; i < 600; i++) {
      update(reactions, 0.016);
    }
    final settled = notified;
    update(reactions, 0.016);
    expect(notified, settled);
  });
}
