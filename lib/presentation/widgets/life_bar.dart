import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/life_meter.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

/// The life bar under the timer (see [LifeMeter]), drawn by
/// `shaders/life_bar.frag`.
///
/// It fills with every block and its color climbs through the stages, it
/// shines and plays a note when a new stage is reached. On a miss the lost
/// half stays for a moment, then crumbles away while the bar shakes. In the
/// danger stage it pulses red.
class LifeBar extends StatefulWidget {
  const LifeBar({super.key});

  static const size = Size(300, 60);

  /// Indexed by the stage, see [LifeMeter.stages]
  static const stageColors = [
    Color(0xFFFF2F3F),
    Color(0xFF00AFFF),
    Color(0xFFFF639F),
    Color(0xFFFF7A1A),
    Color(0xFFFFD66B),
  ];

  @override
  State<LifeBar> createState() => _LifeBarState();
}

class _LifeBarState extends State<LifeBar> with SingleTickerProviderStateMixin {
  static Future<FragmentProgram>? _program;

  FragmentShader? _shader;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final _look = _LifeBarLook();

  @override
  void initState() {
    super.initState();
    final state = context.read<GameCubit>().state;
    _look.snapTo(state.life);
    _look.opacity = _targetOpacity(state);
    _ticker = createTicker(_onTick)..start();
    _program ??= FragmentProgram.fromAsset('shaders/life_bar.frag');
    _program!.then((program) {
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    }, onError: (Object e) => debugPrint('Life bar shader disabled: $e'));
  }

  double _targetOpacity(GameState state) =>
      state.playingState.isPlaying || state.playingState.isPaused ? 1.0 : 0.35;

  void _onTick(Duration elapsed) {
    final dt = min(0.05, (elapsed - _lastElapsed).inMicroseconds / 1000000);
    _lastElapsed = elapsed;
    _look.update(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _look.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listenWhen: (previous, current) =>
          previous.life != current.life ||
          previous.playingState != current.playingState,
      listener: (context, state) {
        _look.targetOpacity = _targetOpacity(state);
        if (state.playingState.isGuide || state.playingState.isNone) {
          _look.snapTo(state.life);
        } else {
          _look.setLife(state.life);
        }
      },
      child: SizedBox.fromSize(
        size: LifeBar.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _LifeBarPainter(shader: _shader, look: _look),
          ),
        ),
      ),
    );
  }
}

/// Everything the bar shows, animated every frame
class _LifeBarLook extends ChangeNotifier {
  double time = 0;
  double life = LifeMeter.start;
  double shown = LifeMeter.start;
  double ghost = 0;
  double ghostAlpha = 0;
  double _ghostDelay = 0;
  double flash = 0;
  double hit = 0;
  double levelUp = 0;
  double danger = 0;
  double full = 0;
  double opacity = 1;
  double targetOpacity = 1;
  Color color = LifeBar.stageColors[LifeMeter.stageOf(LifeMeter.start)];

  int get stage => LifeMeter.stageOf(life);

  void snapTo(double value) {
    life = value;
    shown = value;
    ghostAlpha = 0;
    flash = 0;
    hit = 0;
    levelUp = 0;
    color = LifeBar.stageColors[stage];
    danger = stage == 0 ? 1 : 0;
    full = stage == LifeMeter.lastStage ? 1 : 0;
  }

  void setLife(double value) {
    final previousStage = stage;
    if (value < life) {
      // Keep the lost chunk for a moment, then crumble it
      ghost = max(shown, ghostAlpha > 0 ? ghost : 0);
      ghostAlpha = 1;
      _ghostDelay = 0.35;
      shown = value;
      hit = 1;
    } else if (value > life) {
      flash = 1;
    }
    life = value;
    if (stage > previousStage) {
      levelUp = 1;
    }
  }

  void update(double dt) {
    time += dt;
    // Fills up smoothly, drops at once
    shown += (life - shown) * (1 - exp(-12 * dt));
    if (_ghostDelay > 0) {
      _ghostDelay -= dt;
    } else {
      ghostAlpha = max(0, ghostAlpha - dt * 1.8);
    }
    flash *= exp(-5 * dt);
    hit *= exp(-3.5 * dt);
    levelUp = max(0, levelUp - dt / 0.9);
    final follow = 1 - exp(-8 * dt);
    color = Color.lerp(color, LifeBar.stageColors[stage], follow)!;
    danger += ((stage == 0 && life > 0 ? 1 : 0) - danger) * follow;
    full += ((stage == LifeMeter.lastStage ? 1 : 0) - full) * follow;
    opacity += (targetOpacity - opacity) * follow;
    notifyListeners();
  }
}

class _LifeBarPainter extends CustomPainter {
  _LifeBarPainter({required this.shader, required this.look})
    : super(repaint: look);

  final FragmentShader? shader;
  final _LifeBarLook look;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Shake on a miss, bounce on a new stage
    final shake = sin(look.time * 55) * look.hit * look.hit * 5;
    final scale = 1 + 0.08 * look.levelUp * look.levelUp + 0.02 * look.flash;
    canvas.translate(size.width / 2 + shake, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);

    final bar = Rect.fromLTWH(24, 19, size.width - 48, 22);
    final shader = this.shader;
    if (shader == null) {
      _paintFallback(canvas, bar);
    } else {
      final c = look.color;
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, bar.left)
        ..setFloat(3, bar.top)
        ..setFloat(4, bar.width)
        ..setFloat(5, bar.height)
        ..setFloat(6, look.time)
        ..setFloat(7, look.shown)
        ..setFloat(8, look.ghost)
        ..setFloat(9, look.ghostAlpha)
        ..setFloat(10, look.flash)
        ..setFloat(11, look.hit)
        ..setFloat(12, look.levelUp)
        ..setFloat(13, look.danger)
        ..setFloat(14, look.full)
        ..setFloat(15, c.r)
        ..setFloat(16, c.g)
        ..setFloat(17, c.b)
        ..setFloat(18, look.opacity);
      _paint.shader = shader;
      canvas.drawRect(Offset.zero & size, _paint);
    }
    canvas.restore();
  }

  void _paintFallback(Canvas canvas, Rect bar) {
    final radius = Radius.circular(bar.height / 2);
    final alpha = look.opacity;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, radius),
      Paint()..color = const Color(0xFF15151C).withValues(alpha: alpha),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left, bar.top, bar.width * look.shown, bar.height),
        radius,
      ),
      Paint()..color = look.color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _LifeBarPainter oldDelegate) =>
      oldDelegate.shader != shader;
}
