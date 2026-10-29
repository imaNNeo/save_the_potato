import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/components/sprite_particle_batch.dart';

void main() {
  test('particles move and are recycled after their lifespan', () async {
    final sprite = Sprite(await createTestImage(width: 4, height: 4));
    final batch = SpriteParticleBatch();

    final particle = batch.spawn(sprite: sprite, lifespan: 1.0)
      ..color = const Color(0xFFFF0000);
    particle.acceleration.setValues(10, 0);
    expect(batch.length, 1);

    batch.update(0.5);
    expect(batch.length, 1);
    expect(particle.progress, 0.5);
    expect(particle.position.x, greaterThan(0));

    batch.update(0.6);
    expect(batch.length, 0);

    // The recycled particle comes back reset
    final reused = batch.spawn(sprite: sprite, lifespan: 2.0);
    expect(identical(reused, particle), isTrue);
    expect(reused.elapsed, 0);
    expect(reused.position, Vector2.zero());
    expect(reused.acceleration, Vector2.zero());
  });
}
