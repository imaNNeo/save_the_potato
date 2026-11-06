import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/hit_invincibility.dart';

void main() {
  test('idle until hit, fully visible', () {
    final inv = HitInvincibility();
    expect(inv.isActive, isFalse);
    expect(inv.opacity, 1);
    inv.update(1);
    expect(inv.isActive, isFalse);
  });

  test('a hit gives a safe window that ends after the duration', () {
    final inv = HitInvincibility()..trigger();
    expect(inv.isActive, isTrue);
    inv.update(HitInvincibility.duration - 0.01);
    expect(inv.isActive, isTrue);
    inv.update(0.02);
    expect(inv.isActive, isFalse);
    expect(inv.opacity, 1);
  });

  test('the potato blinks while safe', () {
    final inv = HitInvincibility()..trigger();
    var lowest = 1.0;
    var highest = 0.0;
    for (var i = 0; i < 90; i++) {
      inv.update(1 / 60);
      if (!inv.isActive) break;
      lowest = inv.opacity < lowest ? inv.opacity : lowest;
      highest = inv.opacity > highest ? inv.opacity : highest;
    }
    expect(lowest, lessThan(0.35));
    expect(highest, greaterThan(0.9));
    expect(lowest, greaterThanOrEqualTo(HitInvincibility.minOpacity));
  });

  test('reset ends it right away', () {
    final inv = HitInvincibility()..trigger();
    inv.update(0.1);
    inv.reset();
    expect(inv.isActive, isFalse);
    expect(inv.opacity, 1);
  });

  test('a new hit restarts the window', () {
    final inv = HitInvincibility()..trigger();
    inv.update(1.0);
    inv.trigger();
    expect(inv.remaining, 1);
  });
}
