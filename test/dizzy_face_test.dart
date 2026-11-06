import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/hit_invincibility.dart';
import 'package:save_the_potato/presentation/potato/dizzy_face.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';

void main() {
  test('lasts as long as the hit invincibility', () {
    expect(DizzyFace.duration, HitInvincibility.duration);
    final dizzy = DizzyFace();
    expect(dizzy.isActive, isFalse);
    dizzy.trigger();
    expect(dizzy.isActive, isTrue);
    dizzy.update(DizzyFace.duration - 0.01);
    expect(dizzy.isActive, isTrue);
    dizzy.update(0.02);
    expect(dizzy.isActive, isFalse);
  });

  test('reset stops it right away', () {
    final dizzy = DizzyFace()..trigger();
    dizzy.reset();
    expect(dizzy.isActive, isFalse);
  });

  test('hides the sparkles and smile in the middle of it', () {
    final dizzy = DizzyFace()
      ..trigger()
      ..update(0.8);
    final pose = PotatoPose();
    dizzy.apply(pose);
    expect(pose[PotatoProp.sparkleScaleY], closeTo(0, 1e-9));
    expect(pose[PotatoProp.smileOpacity], closeTo(0, 1e-9));
  });

  test('leaves the pose alone when not active', () {
    final pose = PotatoPose();
    DizzyFace().apply(pose);
    for (final prop in PotatoProp.values) {
      expect(pose[prop], prop.rest);
    }
  });
}
