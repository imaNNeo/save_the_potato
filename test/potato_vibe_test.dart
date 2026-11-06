import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/life_meter.dart';
import 'package:save_the_potato/domain/potato_vibe.dart';

void main() {
  void run(PotatoVibe vibe, double seconds, {double life = 0.5}) {
    const dt = 1 / 60;
    for (var t = 0.0; t < seconds; t += dt) {
      vibe.update(dt, life: life, playing: true);
    }
  }

  test('starts neutral', () {
    final vibe = PotatoVibe();
    expect(vibe.groove, 0);
    expect(vibe.nerves, 0);
    expect(vibe.calm, 0);
    expect(vibe.bliss, 0);
  });

  test('blocked notes get it into the music, up to full', () {
    final vibe = PotatoVibe();
    for (var i = 0; i < 4; i++) {
      vibe.onNote();
    }
    expect(vibe.groove, closeTo(4 * PotatoVibe.perNote, 1e-9));
    for (var i = 0; i < 20; i++) {
      vibe.onNote();
    }
    expect(vibe.groove, 1);
    expect(vibe.bliss, greaterThan(0.9));
  });

  test('every note kicks, and the kick fades fast', () {
    final vibe = PotatoVibe()..onNote();
    expect(vibe.kick, 1);
    run(vibe, 0.3);
    expect(vibe.kick, 0);
  });

  test('the groove holds for a moment, then fades without notes', () {
    final vibe = PotatoVibe();
    for (var i = 0; i < 10; i++) {
      vibe.onNote();
    }
    run(vibe, PotatoVibe.quietWindow - 0.1);
    expect(vibe.groove, 1);
    run(vibe, 3);
    expect(vibe.groove, lessThan(0.6));
  });

  test('a hit shakes it and throws it off the song', () {
    final vibe = PotatoVibe();
    for (var i = 0; i < 10; i++) {
      vibe.onNote();
    }
    vibe.onHit();
    expect(vibe.nerves, 1);
    expect(vibe.groove, closeTo(PotatoVibe.grooveKeptOnHit, 1e-9));
    expect(vibe.calm, 0);
  });

  test('it calms down by itself in a few seconds', () {
    final vibe = PotatoVibe()..onHit();
    // Still clearly shaken once the dizzy face (1.6s) is over
    run(vibe, 1.6);
    expect(vibe.nerves, greaterThan(0.5));
    run(vibe, 2.6);
    expect(vibe.nerves, 0);
  });

  test('blocking notes calms it down faster', () {
    final alone = PotatoVibe()..onHit();
    final helped = PotatoVibe()..onHit();
    for (var i = 0; i < 5; i++) {
      helped.onNote();
    }
    expect(helped.nerves, lessThan(alone.nerves));
    expect(helped.nerves, closeTo(1 - 5 * PotatoVibe.nervesPerNote, 1e-9));
  });

  test('a shaken potato gets into the music slower', () {
    final calm = PotatoVibe()..onNote();
    final shaken = PotatoVibe()
      ..onHit()
      ..onNote();
    expect(shaken.groove, lessThan(calm.groove));
  });

  test('in the danger stage of the life bar it never fully relaxes', () {
    final vibe = PotatoVibe()..onHit();
    run(vibe, 5, life: LifeMeter.danger / 2);
    expect(vibe.nerves, PotatoVibe.dangerNerves);
    for (var i = 0; i < 20; i++) {
      vibe.onNote();
    }
    expect(vibe.nerves, PotatoVibe.dangerNerves);
    // Back out of danger, it relaxes
    run(vibe, 3, life: 0.5);
    expect(vibe.nerves, 0);
  });

  test('a full life bar makes it dance harder', () {
    final half = PotatoVibe();
    final full = PotatoVibe();
    for (var i = 0; i < 10; i++) {
      half.onNote();
      full.onNote();
    }
    run(half, 0.1, life: 0.5);
    run(full, 0.1, life: 1);
    expect(full.dance, greaterThan(half.dance));
    expect(full.dance, closeTo(1, 1e-9));
  });

  test('outside of a run it settles down, reset clears everything', () {
    final vibe = PotatoVibe();
    for (var i = 0; i < 10; i++) {
      vibe.onNote();
    }
    vibe.update(1, life: 0.5, playing: false);
    expect(vibe.groove, lessThan(1));
    vibe
      ..onHit()
      ..reset();
    expect(vibe.groove, 0);
    expect(vibe.nerves, 0);
    expect(vibe.kick, 0);
  });
}
