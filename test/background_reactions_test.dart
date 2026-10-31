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

  void wave(
    BackgroundReactions reactions,
    int frames, {
    bool coming = false,
    bool flying = false,
  }) {
    for (var i = 0; i < frames; i++) {
      reactions.update(
        0.016,
        heat: 0,
        power: 0,
        multiOrbWave: coming || flying,
        multiOrbWaveFlying: flying,
        kickX: 0,
        kickY: 0,
      );
    }
  }

  void withStyle(TenseStyle style) {
    final previous = BackgroundReactions.tenseStyle;
    addTearDown(() => BackgroundReactions.tenseStyle = previous);
    BackgroundReactions.tenseStyle = style;
  }

  test('rush: faster stars and gliding streaks, only during a wave', () {
    withStyle(TenseStyle.rush);
    final reactions = BackgroundReactions();
    wave(reactions, 120, flying: true);
    expect(reactions.tension, greaterThan(0.9));
    expect(reactions.streaks, greaterThan(0.9));
    expect(reactions.speedBoost, greaterThan(2.5));

    wave(reactions, 600);
    expect(reactions.tension, lessThan(0.01));
    expect(reactions.streaks, lessThan(0.01));
    expect(reactions.speedBoost, closeTo(1, 0.05));
  });

  test('inward: the stars fly in towards the potato', () {
    withStyle(TenseStyle.inward);
    final reactions = BackgroundReactions();
    wave(reactions, 120, flying: true);
    expect(reactions.speedBoost, lessThan(-0.5));
    expect(reactions.stretch, lessThan(0));
  });

  test('hush: slow and dim when announced, rushing once flying', () {
    withStyle(TenseStyle.hush);
    final reactions = BackgroundReactions();
    wave(reactions, 150, coming: true);
    expect(reactions.dim, greaterThan(0.6));
    expect(reactions.speedBoost, lessThan(0.5));

    wave(reactions, 150, flying: true);
    expect(reactions.dim, lessThan(0.1));
    expect(reactions.speedBoost, greaterThan(2.5));
  });

  test('lanes glow where the orbs come from and fade after', () {
    withStyle(TenseStyle.lanes);
    final reactions = BackgroundReactions();
    for (var i = 0; i < 120; i++) {
      reactions.updateLanes(0, const Color(0xFFFF0000));
      reactions.updateLanes(pi, const Color(0xFF0000FF));
      wave(reactions, 1, flying: true);
    }
    final lanes = [...reactions.lanes]
      ..sort((a, b) => b.dirX.compareTo(a.dirX));
    expect(lanes.first.amount, greaterThan(0.9));
    expect(lanes.first.dirX, closeTo(1, 0.001));
    expect(lanes.first.r, 1);
    expect(lanes.last.amount, greaterThan(0.9));
    expect(lanes.last.dirX, closeTo(-1, 0.001));
    expect(lanes.last.b, 1);

    wave(reactions, 120);
    expect(reactions.lanes.every((lane) => lane.amount < 0.01), isTrue);
  });

  test('more lanes than slots are skipped', () {
    final reactions = BackgroundReactions();
    for (var i = 0; i < 4; i++) {
      reactions.updateLanes(i * pi / 2, const Color(0xFFFF0000));
    }
    wave(reactions, 1, flying: true);
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
