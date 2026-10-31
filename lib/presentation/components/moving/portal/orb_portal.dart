import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/components/moving/orb/orb_type.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

/// A hole in space that forms at a spot, turns into an orb, then collapses.
///
/// It calls [onOpen] once it has formed, which is when the orb leaves. It
/// stays open until [close] is called, so a wave can pour a whole series out
/// of one portal. [angry] portals (the waves) are bigger and unstable.
class OrbPortal extends PositionComponent
    with FlameBlocListenable<GameCubit, GameState> {
  OrbPortal({
    required this.type,
    required Vector2 position,
    required this.formDuration,
    this.onOpen,
    this.angry = false,
  }) : _seed = Random().nextDouble() * 100,
       super(position: position, anchor: Anchor.center, priority: 0);

  final OrbType type;
  final double formDuration;
  final VoidCallback? onOpen;
  final bool angry;
  final double _seed;

  static const closeDuration = 0.35;

  /// How long every portal shows before it throws. It is the same for all
  /// portals at a given moment, and shrinks evenly from [maxFormDuration]
  /// to [minFormDuration] as the difficulty rises. No random timing and no
  /// sliding, so the player is never tricked.
  static double formDurationFor(double difficulty) =>
      maxFormDuration -
      (maxFormDuration - minFormDuration) * difficulty.clamp(0.0, 1.0);

  /// At the start of a run
  static const maxFormDuration = 0.5;

  /// At full difficulty
  static const minFormDuration = 0.4;

  double _time = 0;
  double _form = 0;
  double? _closing;
  double _kick = 0;
  bool _opened = false;

  bool get isOpen => _opened && _closing == null;

  bool get isClosing => _closing != null;

  /// Collapses and removes itself
  void close() => _closing ??= 0;

  /// Pulses as an orb leaves
  void kick() => _kick = 1;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _kick = max(0, _kick - dt * 4);
    if (!bloc.state.playingState.isPlaying && _closing == null) {
      close();
    }
    if (_closing != null) {
      _closing = _closing! + dt / closeDuration;
      if (_closing! >= 1) {
        removeFromParent();
      }
      return;
    }
    if (!_opened) {
      _form = min(1, _form + dt / formDuration);
      if (_form >= 1) {
        _opened = true;
        _kick = 1;
        onOpen?.call();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final painter = _PortalPainter(
      canvas: canvas,
      type: type,
      t: _time + _seed,
      form: Curves.easeIn.transform(_form),
      raw: _form,
      closing: _closing == null ? 0 : Curves.easeIn.transform(_closing!),
      kick: _kick,
      angry: angry,
    );
    painter.spiral();
  }
}

/// Draws every look a portal can have for the first few frames, clipped to
/// a single pixel under the potato so nobody sees it. The GPU compiles a
/// shader the first time it sees an effect, which drops frames; this makes
/// that happen on the home screen instead of when the first portal, wave or
/// game over shows up mid-game.
///
/// It draws straight on the game canvas (not into a layer), because the GPU
/// keeps separate shaders for layers and the screen.
class PortalWarmUp extends Component {
  PortalWarmUp() : super(priority: -100);

  int _frames = 0;

  @override
  void render(Canvas canvas) {
    canvas
      ..save()
      ..clipRect(const Rect.fromLTWH(0, 0, 1, 1));
    for (final type in OrbType.values) {
      for (final angry in [false, true]) {
        for (final (raw, closing, kick) in [
          (0.3, 0.0, 0.0),
          (0.9, 0.0, 0.0),
          (1.0, 0.0, 0.6),
          (1.0, 0.5, 0.0),
        ]) {
          _PortalPainter(
            canvas: canvas,
            type: type,
            t: raw * 3,
            form: Curves.easeIn.transform(raw),
            raw: raw,
            closing: closing,
            kick: kick,
            angry: angry,
          ).spiral();
        }
      }
    }
    // The blur shader changes with the blur's size on screen, which changes
    // with the camera zoom, so warm up the whole range
    final line = Path()
      ..moveTo(-6, 0.5)
      ..lineTo(6, 0.5);
    for (var sigma = 0.25; sigma <= 8; sigma += 0.25) {
      canvas.drawPath(
        line,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }
    // The game over screen blurs what is behind it, growing to 16
    for (var sigma = 0.5; sigma <= 16; sigma += 0.5) {
      canvas
        ..saveLayer(
          const Rect.fromLTWH(0, 0, 1, 1),
          Paint()
            ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        )
        ..drawRect(
          const Rect.fromLTWH(-2, -2, 5, 5),
          Paint()..color = const Color(0xFF000000),
        )
        ..restore();
    }
    canvas.restore();
    if (++_frames >= 3) {
      removeFromParent();
    }
  }
}

/// Draws one portal around the origin.
///
/// [form] goes 0 to 1 while it forms, [closing] 0 to 1 while it collapses,
/// [kick] pulses when an orb leaves.
class _PortalPainter {
  _PortalPainter({
    required this.canvas,
    required this.type,
    required this.t,
    required this.form,
    required this.raw,
    required this.closing,
    required this.kick,
    required this.angry,
  }) : c = angry ? _angryColors(type) : type.colors,
       // Wave portals are bigger and shake
       size = angry ? 1.2 : 0.85,
       jitter = angry
           ? Offset(sin(t * 53) * 1.2, cos(t * 47) * 1.2)
           : Offset.zero;

  final Canvas canvas;
  final OrbType type;
  final double t, form, closing, kick;

  /// [form] without easing, each look eases it its own way
  final double raw;
  final bool angry;
  final List<Color> c;
  final double size;
  final Offset jitter;

  static const _white = Color(0xFFFFFFFF);

  /// Radius of the orb that comes out (a bit bigger than a flying orb's head)
  static const _orbRadius = 10.0;

  static List<Color> _angryColors(OrbType type) => type.isFire
      ? const [Color(0xFFFFB27A), Color(0xFFFF2F00), Color(0xFFB80F00)]
      : const [Color(0xFFD2EEFF), Color(0xFF2F7BFF), Color(0xFF3A2DD8)];

  void _glow(Offset p, double radius, Color color, double alpha) {
    if (radius <= 0 || alpha <= 0) {
      return;
    }
    canvas.drawCircle(
      p,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(p, radius, [
          color.withValues(alpha: alpha.clamp(0.0, 1.0)),
          color.withValues(alpha: 0),
        ]),
    );
  }

  /// The orb taking shape in the middle, like a flying orb's head
  void _core(double radius) {
    if (radius <= 0.2) {
      return;
    }
    final p = jitter;
    _glow(p, radius * 2.6, c[1], 0.45);
    canvas.drawCircle(
      p,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          p,
          radius,
          [
            Color.lerp(c[0], _white, 0.5)!,
            c[0],
            c[1],
            c[2],
            c[2].withValues(alpha: 0),
          ],
          [0, 0.28, 0.58, 0.82, 1],
        ),
    );
  }

  // Few shapes, additive light, a hard snap at release

  static double _clamp01(double x) => x.clamp(0.0, 1.0);

  /// 0 until [from], then eases up to 1 at the end of forming
  double _late(double from) => _clamp01((raw - from) / (1 - from));

  /// A soft additive bloom
  void _bloom(Offset p, double radius, Color color, double alpha) {
    if (radius <= 0 || alpha <= 0) {
      return;
    }
    canvas.drawCircle(
      p,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          p,
          radius,
          [
            color.withValues(alpha: _clamp01(alpha)),
            color.withValues(alpha: _clamp01(alpha) * 0.25),
            color.withValues(alpha: 0),
          ],
          [0, 0.35, 1],
        ),
    );
  }

  static const _strokeBlur = MaskFilter.blur(BlurStyle.normal, 2.5);

  /// A glowing line: a blurred wide stroke under a thin hot one
  void _lightStroke(Path path, double width, double alpha) {
    if (alpha <= 0) {
      return;
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = c[1].withValues(alpha: _clamp01(alpha * 0.8))
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 3
          ..strokeCap = StrokeCap.round
          // A fixed blur: every new blur size compiles a new GPU shader,
          // which drops frames the first time it shows up
          ..maskFilter = _strokeBlur,
      )
      ..drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = Color.lerp(
            c[0],
            _white,
            0.35,
          )!.withValues(alpha: _clamp01(alpha))
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  }

  /// The pop when the orb leaves: a white flash and a crisp ring
  void _release() {
    final k = closing;
    if (k <= 0) {
      return;
    }
    final fade = 1 - k;
    _bloom(jitter, (10 + 18 * k) * size, _white, 0.9 * fade * fade);
    final ring = Path()
      ..addOval(Rect.fromCircle(center: jitter, radius: (8 + 46 * k) * size));
    _lightStroke(ring, 2.2 * fade + 0.3, fade);
  }

  /// The orb growing in the middle near the end, with a little overshoot
  double get _lateCore {
    final grow = Curves.easeOutBack.transform(_late(0.72));
    return _orbRadius * grow * (1 - closing) * (1 - 0.45 * kick);
  }

  /// A reversed black hole: a single tapered spiral of light winding in faster and faster
  void spiral() {
    final life = min(1.0, raw * 5) * (1 - closing);
    final reach = 36 * size * (1 - 0.45 * Curves.easeIn.transform(raw));
    final spin = t * (angry ? 5 : 2.5) + raw * raw * 9;
    _bloom(jitter, reach, c[1], 0.3 * life);
    final arms = angry ? 3 : 2;
    // Per arm: one blurred glow along its thick inner part, then thin hot
    // segments that taper and brighten toward the middle. Only one blur
    // per arm keeps it cheap.
    const steps = 16;
    final hot = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final hotColor = Color.lerp(c[0], _white, 0.35)!;
    for (var arm = 0; arm < arms; arm++) {
      final points = [
        for (var i = 0; i <= steps; i++)
          () {
            final k = i / steps;
            final a = spin + arm * pi * 2 / arms + k * pi * 2.2;
            return jitter + Offset(cos(a), sin(a)) * (reach * pow(1 - k, 1.25));
          }(),
      ];
      final glow = Path()..moveTo(points[5].dx, points[5].dy);
      for (final p in points.skip(6)) {
        glow.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        glow,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = c[1].withValues(alpha: _clamp01(life * 0.65))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * size
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * size),
      );
      for (var i = 1; i <= steps; i++) {
        final k = i / steps;
        canvas.drawLine(
          points[i - 1],
          points[i],
          hot
            ..color = hotColor.withValues(
              alpha: _clamp01(life * (0.15 + 0.85 * k)),
            )
            ..strokeWidth = (0.4 + 2.0 * k) * size,
        );
      }
    }
    _bloom(jitter, 6 * size, _white, life * 0.6);
    if (angry) {
      _throwPulse();
    }
    _core(_lateCore);
    _release();
  }

  /// An angry portal's punch on every throw: a ring and sparks flying out
  void _throwPulse() {
    if (kick <= 0 || closing > 0) {
      return;
    }
    final out = 1 - kick;
    _lightStroke(
      Path()..addOval(
        Rect.fromCircle(center: jitter, radius: (10 + 28 * out) * size),
      ),
      1.6 * kick * size,
      kick,
    );
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3 + t * 0.7;
      final dir = Offset(cos(a), sin(a));
      final from = jitter + dir * ((12 + 30 * out) * size);
      final to = from + dir * (7 * kick * size);
      _lightStroke(
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy),
        1.4 * size,
        kick,
      );
    }
  }
}
