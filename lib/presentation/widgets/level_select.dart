import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/components/moving/rift/ring_rift.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';

/// Samples of the home screen's level select, picked on the web with
/// `?home=dial|pointer|road`
enum LevelSelectStyle {
  /// The ring of stops turns, the picked one sits at the top
  dial,

  /// The stops stay put and the shields turn to point at one, like in a run
  pointer,

  /// The stops sit on the big arena ring as a road, which turns
  road;

  static final LevelSelectStyle current = () {
    if (!kIsWeb) {
      return LevelSelectStyle.dial;
    }
    final name = Uri.base.queryParameters['home'];
    return LevelSelectStyle.values.firstWhere(
      (s) => s.name == name,
      orElse: () => LevelSelectStyle.dial,
    );
  }();
}

/// The home screen: the endless mode and the ten levels as stops around
/// the potato, turned with the same left/right as the shields in a run,
/// and a START button. Stop 0 is the endless mode, 1 to 10 the levels.
class LevelSelect extends StatefulWidget {
  const LevelSelect({super.key});

  /// Where the fire shield points on the home screen (screen angle)
  static final pointerAngle = ValueNotifier<double>(-pi / 2);

  static const stops = Levels.count + 1;

  /// The screen angle of [stop] when nothing is turned: the endless mode
  /// at the top, the levels going clockwise
  static double stopAngle(double stop) => -pi / 2 + stop * 2 * pi / stops;

  /// Picks the next open level the first time the home screen shows
  static bool _defaulted = false;

  @override
  State<LevelSelect> createState() => _LevelSelectState();
}

class _LevelSelectState extends State<LevelSelect>
    with TickerProviderStateMixin {
  final style = LevelSelectStyle.current;

  /// Where the selector is, in stops (not wrapped: it can go round and
  /// round)
  double _pos = 1;

  /// The stop it eases to when nobody turns it
  double? _snap;

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  late final AnimationController _pulse;
  late final AnimationController _intro;

  /// Stops per second while left or right is held
  static const _turnSpeed = 3.2;

  GameCubit get _cubit => context.read<GameCubit>();

  int get _selected =>
      (_pos.round() % LevelSelect.stops + LevelSelect.stops) %
      LevelSelect.stops;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<GameCubit>();
    var level = cubit.state.level;
    if (!LevelSelect._defaulted) {
      LevelSelect._defaulted = true;
      if (level == null) {
        level = Levels.nextAfter(cubit.state.levelsCleared);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => cubit.selectLevel(level),
        );
      }
    }
    _pos = (level ?? 0).toDouble();
    _snap = _pos;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _ticker = createTicker(_tick)..start();
    _updatePointer();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 0.0
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    final state = _cubit.state;
    if (!state.playingState.isGuide) {
      return;
    }
    final before = _pos;
    final direction = state.shieldsTurnDirection;
    if (direction != 0) {
      _pos += direction * _turnSpeed * dt;
      _snap = null;
    } else {
      final snap = _snap ??= _pos.roundToDouble();
      _pos += (snap - _pos) * min(1.0, dt * 14);
      if ((snap - _pos).abs() < 0.001) {
        _pos = snap;
      }
    }
    if (_pos != before) {
      _updatePointer();
      _pickSelected();
      setState(() {});
    }
  }

  void _pickSelected() {
    final stop = _selected;
    final level = stop == 0 ? null : stop;
    if (_cubit.state.level != level) {
      _cubit.selectLevel(level);
    }
  }

  void _updatePointer() {
    LevelSelect.pointerAngle.value = style == LevelSelectStyle.pointer
        ? LevelSelect.stopAngle(_pos)
        : -pi / 2;
  }

  /// Turns to [stop] the short way round
  void _goTo(int stop) {
    final n = LevelSelect.stops;
    var delta = (stop - _pos.round()) % n;
    if (delta > n / 2) {
      delta -= n;
    }
    _snap = _pos.roundToDouble() + delta;
  }

  void _step(int by) => _snap = (_snap ?? _pos.roundToDouble()) + by;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.level != b.level || a.levelsCleared != b.levelsCleared,
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          // The camera fits the 720 world units square in the screen
          final scale =
              min(constraints.maxWidth, constraints.maxHeight) /
              GameConstants.viewSize;
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          return AnimatedBuilder(
            animation: Listenable.merge([_pulse, _intro]),
            builder: (context, _) => Stack(
              children: [
                if (style == LevelSelectStyle.road)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RoadPainter(
                          center: center,
                          radius: _radius(scale),
                          turn: _turn,
                          cleared: state.levelsCleared,
                          intro: _intro.value,
                        ),
                      ),
                    ),
                  ),
                if (style != LevelSelectStyle.pointer) _marker(center, scale),
                ..._stops(state, center, scale),
                _title(),
                _panel(state),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- the stops ----

  double _radius(double scale) => switch (style) {
    LevelSelectStyle.road => ArenaRing.radius * 0.92 * scale,
    _ => 168 * scale,
  };

  /// How far the ring is turned, in radians
  double get _turn =>
      style == LevelSelectStyle.pointer ? 0 : _pos * 2 * pi / LevelSelect.stops;

  List<Widget> _stops(GameState state, Offset center, double scale) {
    final radius = _radius(scale);
    final base = style == LevelSelectStyle.road ? 40.0 : 34.0;
    final widgets = <(double, Widget)>[];
    for (var stop = 0; stop < LevelSelect.stops; stop++) {
      // Each stop pops out a little after the one before
      final t = (_intro.value * 1.6 - stop * 0.05).clamp(0.0, 1.0);
      if (t <= 0) {
        continue;
      }
      final angle = LevelSelect.stopAngle(stop.toDouble()) - _turn;
      // How close it is to being picked, 1 when it is
      final d = _distance(stop);
      final near = (1 - d).clamp(0.0, 1.0);
      final size = base * (1 + 0.35 * near);
      final r = radius * Curves.easeOutBack.transform(t);
      final level = stop == 0 ? null : stop;
      widgets.add((
        near,
        Positioned(
          left: center.dx + cos(angle) * r - size / 2,
          top: center.dy + sin(angle) * r - size / 2,
          width: size,
          height: size,
          child: Opacity(
            opacity: t,
            child: _Stop(
              level: level,
              cleared: level != null && level <= state.levelsCleared,
              open: level == null || Levels.isOpen(level, state.levelsCleared),
              selected: near,
              pulse: _pulse.value,
              onTap: () => _goTo(stop),
            ),
          ),
        ),
      ));
    }
    // The picked one on top
    widgets.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final w in widgets) w.$2];
  }

  /// How far [stop] is from the selector, in stops, the short way round
  double _distance(int stop) {
    final n = LevelSelect.stops;
    final d = ((stop - _pos) % n + n) % n;
    return min(d, n - d);
  }

  /// The notch at the top the picked stop sits under
  Widget _marker(Offset center, double scale) {
    final r = _radius(scale);
    final y = center.dy - r - (style == LevelSelectStyle.road ? 40 : 34);
    return Positioned(
      left: center.dx - 9,
      top: y - 4 + 3 * _pulse.value,
      child: Opacity(
        opacity: _intro.value,
        child: CustomPaint(
          size: const Size(18, 12),
          painter: _ArrowPainter(Colors.white.withValues(alpha: 0.9)),
        ),
      ),
    );
  }

  // ---- text and START ----

  Widget _title() => Align(
    alignment: Alignment.topCenter,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Opacity(
          opacity: _intro.value,
          child: const Text(
            'SAVE THE POTATO',
            style: TextStyle(fontFamily: 'Cookies', fontSize: 30),
          ),
        ),
      ),
    ),
  );

  Widget _panel(GameState state) {
    final level = state.level;
    final locked = level != null && !Levels.isOpen(level, state.levelsCleared);
    final accent = level == null
        ? const Color(0xFFC9B8FF)
        : Color(Levels.songOf(level).colors.first);
    final String name;
    final String caption;
    if (level == null) {
      name = 'ENDLESS';
      caption = 'No finish line: survive as long as you can';
    } else if (locked) {
      name = 'LEVEL $level';
      caption = 'Clear level ${level - 1} to unlock it';
    } else if (level <= state.levelsCleared) {
      name = 'LEVEL $level';
      caption = 'Cleared! Play it again any time';
    } else {
      name = 'LEVEL $level';
      caption = 'Clear a level to unlock the next one';
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
          child: Opacity(
            opacity: _intro.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Chevron(left: true, onTap: () => _step(-1)),
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Cookies',
                              fontSize: 30,
                              shadows: [Shadow(blurRadius: 12, color: accent)],
                            ),
                          ),
                          Text(
                            level == null
                                ? 'INFINITE MODE'
                                : Levels.songOf(level).name.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Cookies',
                              fontSize: 17,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Chevron(left: false, onTap: () => _step(1)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 18),
                _StartButton(
                  accent: accent,
                  locked: locked,
                  pulse: _pulse.value,
                  onTap: locked ? null : _cubit.startFromHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.level,
    required this.cleared,
    required this.open,
    required this.selected,
    required this.pulse,
    required this.onTap,
  });

  /// Null for the endless mode
  final int? level;
  final bool cleared;
  final bool open;

  /// 1 when it is picked, 0 when it is a stop or more away
  final double selected;
  final double pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF120A1E);
    final level = this.level;
    final Color fill;
    final Widget child;
    if (level == null) {
      fill = const Color(0xFFC9B8FF);
      child = const FittedBox(
        child: Padding(
          padding: EdgeInsets.all(5),
          child: Icon(Icons.all_inclusive_rounded, color: ink),
        ),
      );
    } else if (cleared) {
      fill = GameColors.leaderboardGoldenColor;
      child = const FittedBox(
        child: Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.check_rounded, color: ink),
        ),
      );
    } else if (open) {
      fill = Color(Levels.songOf(level).colors.first);
      child = FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Text(
            '$level',
            style: const TextStyle(
              fontFamily: 'Cookies',
              fontSize: 16,
              color: ink,
              height: 1.1,
            ),
          ),
        ),
      );
    } else {
      fill = Colors.white.withValues(alpha: 0.12);
      child = const FittedBox(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.lock_rounded, color: Colors.white60),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: selected > 0.5
              ? Border.all(color: Colors.white, width: 2.5)
              : null,
          boxShadow: selected > 0.05
              ? [
                  BoxShadow(
                    color: fill.withValues(alpha: 0.8 * selected),
                    blurRadius: (14 + pulse * 10) * selected,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.left, required this.onTap});

  final bool left;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Icon(
        left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        size: 34,
        color: Colors.white70,
      ),
    ),
  );
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.accent,
    required this.locked,
    required this.pulse,
    required this.onTap,
  });

  final Color accent;
  final bool locked;
  final double pulse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF120A1E);
    final color = locked
        ? Colors.white.withValues(alpha: 0.12)
        : Color.lerp(accent, Colors.white, 0.15)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.scale(
        scale: locked ? 1 : 1 + 0.03 * pulse,
        child: Container(
          width: 220,
          height: 58,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(29),
            boxShadow: locked
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 18 + 8 * pulse,
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                color: locked ? Colors.white54 : ink,
                size: 28,
              ),
              const SizedBox(width: 6),
              Text(
                locked ? 'LOCKED' : 'START',
                style: TextStyle(
                  fontFamily: 'Cookies',
                  fontSize: 26,
                  color: locked ? Colors.white54 : ink,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}

/// The road between the stops on the arena ring: gold where the levels
/// are cleared, dotted where they are still to come
class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.center,
    required this.radius,
    required this.turn,
    required this.cleared,
    required this.intro,
  });

  final Offset center;
  final double radius;
  final double turn;
  final int cleared;
  final double intro;

  @override
  void paint(Canvas canvas, Size size) {
    const n = LevelSelect.stops;
    final step = 2 * pi / n;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var stop = 0; stop < n; stop++) {
      final from = LevelSelect.stopAngle(stop.toDouble()) - turn;
      // From the endless stop to 1 and from 10 back round: plain. Between
      // two cleared levels (or into the first): gold.
      final done = stop >= 1 && stop < cleared;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = done ? 4 : 2
        ..color = (done ? GameColors.leaderboardGoldenColor : Colors.white)
            .withValues(alpha: (done ? 0.85 : 0.25) * intro);
      if (done) {
        canvas.drawArc(rect, from + 0.12, step - 0.24, false, paint);
      } else {
        // Dotted
        const dots = 5;
        for (var i = 1; i < dots; i++) {
          final a = from + step * i / dots;
          canvas.drawCircle(
            center + Offset(cos(a), sin(a)) * radius,
            1.6,
            paint..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.turn != turn ||
      old.cleared != cleared ||
      old.intro != intro ||
      old.radius != radius;
}
