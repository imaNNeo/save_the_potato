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
    this.drift = 0,
  }) : _seed = Random().nextDouble() * 100,
       super(position: position, anchor: Anchor.center, priority: 0);

  final OrbType type;
  final double formDuration;
  final VoidCallback? onOpen;
  final bool angry;

  /// How fast it slides around the potato while forming (radians/second)
  final double drift;
  final double _seed;

  static const closeDuration = 0.35;

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
      if (drift != 0) {
        position.rotate(drift * dt);
      }
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
      closing: _closing == null ? 0 : Curves.easeIn.transform(_closing!),
      kick: _kick,
      angry: angry,
    );
    painter.whiteHole();
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
    required this.closing,
    required this.kick,
    required this.angry,
  }) : c = angry ? _angryColors(type) : type.colors,
       // Wave portals are bigger and shake
       size = angry ? 1.75 : 1.35,
       jitter = angry
           ? Offset(sin(t * 53) * 1.2, cos(t * 47) * 1.2)
           : Offset.zero;

  final Canvas canvas;
  final OrbType type;
  final double t, form, closing, kick;
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

  /// How alive the portal is overall: grows in, dies out
  double get _life => min(1.0, form * 4) * (1 - closing);

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

  /// A ring that rushes out and fades when it collapses
  void _shockwave() {
    if (closing <= 0) {
      return;
    }
    canvas.drawCircle(
      jitter,
      (14 + 40 * closing) * size,
      Paint()
        ..color = c[0].withValues(alpha: 0.6 * (1 - closing))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - closing) + 0.5,
    );
  }

  /// The orb's size: grows while forming, pops out on a kick, then
  /// shrinks away as the portal collapses
  double get _coreRadius =>
      _orbRadius * form * (1 - closing) * (1 - 0.45 * kick);

  /// A reversed black hole. Sparks spiral in and gather into the orb
  void whiteHole() {
    final life = _life;
    final reach = 46.0 * size;
    _glow(jitter, reach * 1.2, c[1], 0.45 * life);
    // Faint swirl arms
    final spin = t * (angry ? 3.2 : 1.6);
    for (var arm = 0; arm < 3; arm++) {
      final path = Path();
      for (var i = 0; i <= 16; i++) {
        final k = i / 16;
        final a = spin + arm * pi * 2 / 3 + k * 2.6;
        final r = reach * (1 - k * 0.85) * (0.6 + 0.4 * form);
        final p = jitter + Offset(cos(a), sin(a)) * r;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = c[1].withValues(alpha: 0.75 * life)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * size
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    // Sparks falling inward along a spiral
    final count = angry ? 26 : 18;
    for (var i = 0; i < count; i++) {
      final phase = (i * 0.618034) % 1;
      final k = (t * (angry ? 1.4 : 0.9) + phase) % 1;
      final a = i * 2.39996 + spin * 0.6 + k * 3.0;
      final r = reach * (1 - k);
      final p = jitter + Offset(cos(a), sin(a)) * r;
      final alpha = life * sin(k * pi) * 0.95;
      canvas.drawCircle(
        p,
        (1.2 + 2.0 * (1 - k)) * size,
        Paint()
          ..color = Color.lerp(c[0], _white, 0.4)!.withValues(alpha: alpha),
      );
    }
    _core(_coreRadius);
    _shockwave();
  }
}
