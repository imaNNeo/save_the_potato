// PROTOTYPE tool: renders close-up frames of every recovery face to PNG.
// OUT=/some/dir flutter test test/prototype/recovery_faces_frames_test.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:save_the_potato/domain/hit_invincibility.dart';
import 'package:save_the_potato/presentation/potato/potato_animator.dart';
import 'package:save_the_potato/presentation/potato/potato_painter.dart';
import 'package:save_the_potato/presentation/potato/potato_pose.dart';
import 'package:save_the_potato/presentation/potato/recovery_face.dart';

const w = 960, h = 540, fps = 30;

void main() {
  final out = Platform.environment['OUT'];
  if (out == null) return;
  for (final style in RecoveryStyle.values) {
    test('frames ${style.name}', () async {
      final dir = Directory('$out/${style.name}')..createSync(recursive: true);
      final animator = PotatoAnimator();
      final recovery = RecoveryFace(style: style);
      final blink = HitInvincibility();
      final pose = PotatoPose();
      // (time, element, angle the orb comes from)
      final hits = [
        (0.5, RecoveryHit.fire, -2.4),
        (2.9, RecoveryHit.ice, -0.5),
      ];
      const total = 5.2;
      const dt = 1 / fps;
      var t = 0.0;
      for (var f = 0; f < total * fps; f++) {
        for (final (at, kind, angle) in hits) {
          if (t < at && t + dt >= at) {
            kind == RecoveryHit.fire ? animator.fireHit() : animator.iceHit();
            recovery.trigger(kind, angle);
            blink.trigger();
          }
        }
        animator.update(dt);
        recovery.update(dt);
        blink.update(dt);
        t += dt;
        pose.copyFrom(animator.pose);
        recovery.apply(pose);

        final rec = PictureRecorder();
        final c = Canvas(rec);
        c.drawRect(
          Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
          Paint()..color = const Color(0xFF101426),
        );
        // Close-up on the left, game size on the right
        for (final (center, box) in [
          (const Offset(330, 270), 560.0),
          (const Offset(800, 270), 152.0),
        ]) {
          // Incoming orb
          for (final (at, kind, angle) in hits) {
            final k = (at - t) / 0.3;
            if (k > 0 && k < 1) {
              final d = box * (0.28 + k * 0.5);
              c.drawCircle(
                center + Offset(cos(angle), sin(angle)) * d,
                box * 0.06,
                Paint()
                  ..color = kind == RecoveryHit.fire
                      ? const Color(0xFFFF6A2B)
                      : const Color(0xFF6FD3FF),
              );
            }
          }
          c.save();
          c.translate(center.dx - box / 2, center.dy - box / 2);
          final o = blink.opacity;
          if (o < 1) {
            c.saveLayer(
              null,
              Paint()..color = Color.fromRGBO(255, 255, 255, o),
            );
          }
          c.scale(box / PotatoPainter.artboardSize);
          recovery.transform(c);
          PotatoPainter.paint(c, pose);
          recovery.paintOver(c, pose);
          if (o < 1) c.restore();
          c.restore();
        }
        final img = await rec.endRecording().toImage(w, h);
        final bytes = await img.toByteData(format: ImageByteFormat.png);
        File('${dir.path}/f${f.toString().padLeft(4, '0')}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    });
  }
}
