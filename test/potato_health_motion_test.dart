import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/health_mood.dart';
import 'package:save_the_potato/presentation/potato/potato_health_motion.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';

void main() {
  PotatoPose run(
    PotatoHealthMotion motion, {
    required double life,
    bool playing = true,
    bool faceFree = true,
    double seconds = 2,
  }) {
    final pose = PotatoPose();
    for (var t = 0.0; t < seconds; t += 1 / 60) {
      motion.update(
        1 / 60,
        pose,
        life: life,
        playing: playing,
        faceFree: faceFree,
      );
    }
    return pose;
  }

  test('plenty of life: calm, eyes closed, rosy cheeks', () {
    final motion = PotatoHealthMotion();
    final pose = run(motion, life: 0.9);
    expect(motion.mood, HealthMood.calm);
    expect(pose[PotatoProp.eyeBliss], greaterThan(0.95));
    expect(pose[PotatoProp.blush], greaterThan(0.95));
    expect(pose[PotatoProp.pale], lessThan(0.05));
    expect(pose[PotatoProp.nervousMouth], lessThan(0.05));
  });

  test('next miss ends the run: worried, pale, wobbly mouth', () {
    final motion = PotatoHealthMotion();
    final pose = run(motion, life: 0.1);
    expect(motion.mood, HealthMood.worried);
    expect(pose[PotatoProp.nervousMouth], greaterThan(0.95));
    expect(pose[PotatoProp.browWorry], greaterThan(0.95));
    expect(pose[PotatoProp.pale], greaterThan(0.95));
    expect(pose[PotatoProp.eyeBliss], lessThan(0.05));
    expect(pose[PotatoProp.sparkleSize], lessThan(0.7));
  });

  test('in between leaves the face open and normal', () {
    final motion = PotatoHealthMotion();
    final pose = run(motion, life: 0.5);
    expect(motion.mood, HealthMood.normal);
    expect(pose[PotatoProp.eyeBliss], lessThan(0.05));
    expect(pose[PotatoProp.pale], lessThan(0.05));
    expect(pose[PotatoProp.sparkleSize], closeTo(1, 0.01));
  });

  test('outside of a run it stays normal', () {
    final motion = PotatoHealthMotion();
    run(motion, life: 0.1, playing: false);
    expect(motion.mood, HealthMood.normal);
  });

  test('a clip that owns the face keeps its eyes and mouth', () {
    final motion = PotatoHealthMotion();
    final pose = run(motion, life: 0.9, faceFree: false);
    expect(pose[PotatoProp.eyeBliss], lessThan(0.05));
  });
}
