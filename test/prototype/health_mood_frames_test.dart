import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/presentation/potato/health_mood.dart';
import 'package:save_the_potato/presentation/potato/potato_painter.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';

void main() {
  final out = Platform.environment['OUT'];
  test('health mood stills', () async {
    if (out == null) return;
    for (final style in HealthMoodStyle.values) {
      for (final life in [0.9, 0.5, 0.3, 0.1]) {
        final mood = HealthMood(style)..attach();
        final pose = PotatoPose()..[PotatoProp.headphones] = 1;
        for (var i = 0; i < 90; i++) {
          final p = PotatoPose()..copyFrom(pose);
          mood.update(1 / 60, p, life: life, playing: true, faceFree: true);
          if (i == 89) pose.copyFrom(p);
        }
        final rec = PictureRecorder();
        final c = Canvas(rec);
        c.drawRect(
          const Rect.fromLTWH(0, 0, 300, 300),
          Paint()..color = const Color(0xFF101528),
        );
        c.save();
        c.translate(0, 10);
        c.scale(300 / 500);
        PotatoPainter.paint(c, pose);
        c.restore();
        final img = await rec.endRecording().toImage(300, 300);
        final bytes = await img.toByteData(format: ImageByteFormat.png);
        File('$out/${style.name}-$life.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        mood.detach();
      }
    }
  });
}
