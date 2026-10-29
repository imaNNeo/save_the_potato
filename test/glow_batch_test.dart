import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/components/glow_batch.dart';

void main() {
  const color = Color(0xFFFF5900);

  test('shapes add vertices, invisible ones are skipped', () {
    final batch = GlowBatch();
    expect(batch.isEmpty, isTrue);

    batch.addDisc(0, 0, 20, color, 0);
    batch.addRing(0, 0, 20, 4, color, 0);
    batch.addStreak(0, 0, 10, 0, 2, color, color, 0);
    expect(batch.isEmpty, isTrue);

    batch.addStreak(0, 0, 10, 0, 2, color, color, 1);
    expect(batch.vertexCount, 5);

    batch.addDisc(0, 0, 20, color, 1);
    batch.addRing(0, 0, 20, 4, color, 1, facing: 0);
    batch.addArcBand(0, 0, -0.5, 1, 10, 6, color, (_) => 60, (_) => 1);
    expect(batch.isEmpty, isFalse);

    batch.clear();
    expect(batch.isEmpty, isTrue);
    expect(batch.vertexCount, 0);
  });

  test('tails get a body and a round cap, invisible ones are skipped', () {
    final batch = GlowBatch()
      ..addTail(0, 0, 1, 0, 50, 10, color, color, 0)
      ..addTail(0, 0, 1, 0, 0, 10, color, color, 1);
    expect(batch.isEmpty, isTrue);

    batch.addTail(0, 0, 1, 0, 50, 10, color, color, 1, segments: 4);
    expect(batch.vertexCount, 3 * 5 + 7);

    batch.addTail(0, 0, 0, 1, 50, 10, color, color, 1, wave: 4, wavePhase: 1);
    expect(batch.vertexCount, 2 * (3 * 5 + 7) + 3 * 4);

    final recorder = PictureRecorder();
    batch.render(Canvas(recorder));
    recorder.endRecording().dispose();
  });

  test('bigger circles get more segments', () {
    final small = GlowBatch()..addRing(0, 0, 20, 4, color, 1);
    final big = GlowBatch()..addRing(0, 0, 300, 4, color, 1);
    expect(big.vertexCount, greaterThan(small.vertexCount));
  });

  test('grows past its initial capacity and draws', () {
    final batch = GlowBatch();
    for (var i = 0; i < 200; i++) {
      batch.addDisc(i.toDouble(), 0, 200, color, 1);
    }
    expect(batch.vertexCount, greaterThan(10000));

    final recorder = PictureRecorder();
    batch.render(Canvas(recorder));
    recorder.endRecording().dispose();
  });
}
