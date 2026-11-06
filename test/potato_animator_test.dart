import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/potato/potato_animator.dart';
import 'package:save_the_potato/presentation/potato/potato_clips.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';

void main() {
  void run(PotatoAnimator animator, double seconds) {
    const dt = 1 / 60;
    for (var t = 0.0; t < seconds; t += dt) {
      animator.update(dt);
    }
  }

  group('PotatoClip', () {
    test('holds before the first key and after the last key', () {
      final pose = PotatoPose();
      PotatoClips.fireHit.apply(pose, 0);
      expect(pose[PotatoProp.fireTint], 0);
      PotatoClips.fireHit.apply(pose, 0.2);
      expect(pose[PotatoProp.fireTint], 1);
      PotatoClips.fireHit.apply(pose, 5);
      expect(pose[PotatoProp.fireTint], 0);
    });

    test('moves linearly between keys', () {
      final pose = PotatoPose();
      // Heart opacity goes 0 -> 1 over the first 4 frames.
      PotatoClips.heartHit.apply(pose, 2 / 60);
      expect(pose[PotatoProp.heartOpacity], closeTo(0.5, 1e-9));
    });

    test('the idle clip loops and blinks', () {
      final pose = PotatoPose();
      PotatoClips.idle.apply(pose, 33 / 60);
      expect(pose[PotatoProp.sparkleScaleY], closeTo(0, 1e-9));
      PotatoClips.idle.apply(pose, 3 + 33 / 60);
      expect(pose[PotatoProp.sparkleScaleY], closeTo(0, 1e-9));
    });
  });

  group('PotatoAnimator', () {
    test('a hit plays once, then the potato idles again', () {
      final animator = PotatoAnimator();
      animator.fireHit();
      expect(animator.mood, PotatoMood.reacting);
      run(animator, 0.2);
      expect(animator.pose[PotatoProp.fireTint], 1);
      run(animator, 1);
      expect(animator.mood, PotatoMood.idle);
      expect(animator.pose[PotatoProp.fireTint], 0);
    });

    test('a scared potato ignores hits and calms down on request', () {
      final animator = PotatoAnimator()..scared();
      run(animator, 0.5);
      expect(animator.mood, PotatoMood.scared);
      expect(animator.pose[PotatoProp.zigzagOpacity], 1);
      animator.iceHit();
      expect(animator.mood, PotatoMood.scared);
      animator.calmDown();
      run(animator, 0.5);
      expect(animator.mood, PotatoMood.idle);
      expect(animator.pose[PotatoProp.smileOpacity], 1);
      expect(animator.pose[PotatoProp.zigzagOpacity], 0);
    });

    test('dying works even in the middle of a hit', () {
      final animator = PotatoAnimator()..fireHit();
      run(animator, 0.1);
      animator.die();
      run(animator, 2);
      expect(animator.mood, PotatoMood.dead);
      expect(animator.pose[PotatoProp.frownOpacity], 1);
      expect(animator.pose[PotatoProp.sparkleScaleY], 0);
      animator.heartHit();
      expect(animator.mood, PotatoMood.dead);
    });

    test('a scared potato calms down before it dies', () {
      final animator = PotatoAnimator()..scared();
      run(animator, 0.5);
      animator.die();
      run(animator, 2);
      expect(animator.mood, PotatoMood.dead);
      expect(animator.pose[PotatoProp.zigzagOpacity], 0);
      expect(animator.pose[PotatoProp.frownOpacity], 1);
    });

    test('respawn brings the smile back, then idles', () {
      final animator = PotatoAnimator()..die();
      run(animator, 2);
      animator.respawn();
      run(animator, 2);
      expect(animator.mood, PotatoMood.idle);
      expect(animator.pose[PotatoProp.frownOpacity], 0);
      expect(animator.pose[PotatoProp.smileScaleY], 1);
    });

    test('the intro opens the eyes and then idles', () {
      final animator = PotatoAnimator(intro: true);
      expect(animator.mood, PotatoMood.intro);
      expect(animator.pose[PotatoProp.sparkleScaleY], 0);
      run(animator, 2.1);
      expect(animator.mood, PotatoMood.idle);
    });
  });
}
