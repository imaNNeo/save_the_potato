import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';

/// The home screen: the endless mode and the ten levels as stops around
/// the potato, turned with the same left/right as the shields in a run,
/// and a START button. Stop 0 is the endless mode, 1 to 10 the levels.
class LevelSelect extends StatefulWidget {
  const LevelSelect({super.key});

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
  /// Where the selector is, in stops (not wrapped: it can go round and
  /// round)
  double _pos = 1;

  /// The stop it eases to when nobody turns it
  double? _snap;

  /// Whether it should sit on the next level to clear (until the player
  /// turns it). The cleared count loads a moment after the screen shows.
  bool _followNext = false;

  /// Whether the player has turned the selector yet. Until then, picks are
  /// the screen settling on its default, so they don't play the level's
  /// note (it would blast out at whatever volume the device is on).
  bool _playerTurned = false;

  /// The way left/right was held last frame, and the stop it started from:
  /// letting go always lands on the next stop that way, so a single tap
  /// moves one level
  int _heldDirection = 0;
  double _heldFrom = 0;

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
        _followNext = true;
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
    if (_followNext) {
      final next = Levels.nextAfter(state.levelsCleared).toDouble();
      if (_snap != next) {
        _snap = next;
      }
    }
    if (direction != 0 && _heldDirection == 0) {
      _heldFrom = _snap ?? _pos.roundToDouble();
    } else if (direction == 0 && _heldDirection != 0) {
      var to = _heldDirection > 0 ? _pos.ceilToDouble() : _pos.floorToDouble();
      if ((to - _heldFrom) * _heldDirection < 1) {
        to = _heldFrom + _heldDirection;
      }
      _snap = to;
    }
    _heldDirection = direction.sign.toInt();
    if (direction != 0) {
      _followNext = false;
      _playerTurned = true;
      _pos += direction * _turnSpeed * dt;
      _snap = null;
    } else {
      final snap = _snap ??= _pos.roundToDouble();
      _pos += (snap - _pos) * min(1.0, dt * 14);
      if ((snap - _pos).abs() < 0.001) {
        _pos = snap;
      }
    }
    // Also keeps the game's pick in step when it ignored an earlier one
    _pickSelected();
    if (_pos != before) {
      setState(() {});
    }
  }

  void _pickSelected() {
    final stop = _selected;
    final level = stop == 0 ? null : stop;
    if (_cubit.state.level != level) {
      _cubit.selectLevel(level, playNote: _playerTurned);
    }
  }

  /// Turns to [stop] the short way round
  void _goTo(int stop) {
    _followNext = false;
    _playerTurned = true;
    final n = LevelSelect.stops;
    var delta = (stop - _pos.round()) % n;
    if (delta > n / 2) {
      delta -= n;
    }
    _snap = _pos.roundToDouble() + delta;
  }

  void _step(int by) {
    _followNext = false;
    _playerTurned = true;
    _snap = (_snap ?? _pos.roundToDouble()) + by;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.level != b.level || a.levelsCleared != b.levelsCleared,
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          final layout = _HomeLayout.of(
            Size(constraints.maxWidth, constraints.maxHeight),
            MediaQuery.paddingOf(context),
          );
          return AnimatedBuilder(
            animation: Listenable.merge([_pulse, _intro]),
            builder: (context, _) => Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _LevelPathPainter(
                        center: layout.center,
                        radius: layout.radius,
                        beadScale: layout.beadScale,
                        turn: _turn,
                        cleared: state.levelsCleared,
                        intro: _intro.value,
                      ),
                    ),
                  ),
                ),
                _marker(layout),
                ..._stops(state, layout),
                ..._texts(state, layout),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- the stops ----

  /// How far the ring is turned, in radians
  double get _turn => _pos * 2 * pi / LevelSelect.stops;

  List<Widget> _stops(GameState state, _HomeLayout layout) {
    final center = layout.center;
    final radius = layout.radius;
    final base = 34.0 * layout.beadScale;
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
  Widget _marker(_HomeLayout layout) {
    final y = layout.center.dy - layout.radius - 34 * layout.beadScale;
    return Positioned(
      left: layout.center.dx - 9,
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

  /// The title and the panel (level name, caption, START), placed by
  /// [layout]
  List<Widget> _texts(GameState state, _HomeLayout layout) {
    final info = _PanelInfo.of(state);
    final opacity = _intro.value;
    Widget fade(Widget child) => Opacity(opacity: opacity, child: child);
    switch (layout.mode) {
      case _Mode.stacked:
        // Title above the ring, panel below it (the portrait home)
        final u = layout.uiScale;
        return [
          Positioned(
            left: 0,
            right: 0,
            top: layout.padding.top + 64 * u,
            child: fade(Center(child: _titleText(30 * u))),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: layout.padding.bottom + 40 * u,
            child: fade(
              Center(
                child: Transform.scale(
                  scale: u,
                  alignment: Alignment.bottomCenter,
                  child: _panelColumn(info),
                ),
              ),
            ),
          ),
        ];
      case _Mode.sides:
        // Title on the left of the ring, panel on the right
        final side = layout.sideWidth;
        final top = layout.padding.top + 64;
        final bottom = layout.padding.bottom + 16;
        return [
          Positioned(
            left: layout.padding.left + 12,
            width: side,
            top: top,
            bottom: bottom,
            child: fade(
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _titleText(38, stacked: true),
                ),
              ),
            ),
          ),
          Positioned(
            right: layout.padding.right + 12,
            width: side,
            top: top,
            bottom: bottom,
            child: fade(
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _panelColumn(info),
                ),
              ),
            ),
          ),
        ];
    }
  }

  Widget _titleText(double size, {bool stacked = false}) => Text(
    stacked ? 'SAVE\nTHE\nPOTATO' : 'SAVE THE POTATO',
    textAlign: TextAlign.center,
    style: TextStyle(fontFamily: 'Cookies', fontSize: size, height: 1.05),
  );

  Widget _panelColumn(_PanelInfo info) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _nameRow(info),
      const SizedBox(height: 6),
      _captionText(info),
      const SizedBox(height: 18),
      _startButton(info),
    ],
  );

  Widget _nameRow(_PanelInfo info) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Chevron(left: true, onTap: () => _step(-1)),
      SizedBox(
        width: 200,
        child: Column(
          children: [
            Text(
              info.name,
              style: TextStyle(
                fontFamily: 'Cookies',
                fontSize: 30,
                shadows: [Shadow(blurRadius: 12, color: info.accent)],
              ),
            ),
            Text(
              info.song,
              style: TextStyle(
                fontFamily: 'Cookies',
                fontSize: 17,
                color: info.accent,
              ),
            ),
          ],
        ),
      ),
      _Chevron(left: false, onTap: () => _step(1)),
    ],
  );

  Widget _captionText(_PanelInfo info) => Text(
    info.caption,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 13, color: Colors.white60),
  );

  Widget _startButton(_PanelInfo info) => _StartButton(
    accent: info.accent,
    gradient: info.endless ? _endlessGradient : null,
    locked: info.locked,
    pulse: _pulse.value,
    onTap: info.locked ? null : _cubit.startFromHome,
  );
}

/// What the panel says about the picked stop
class _PanelInfo {
  const _PanelInfo({
    required this.endless,
    required this.locked,
    required this.accent,
    required this.name,
    required this.song,
    required this.caption,
  });

  factory _PanelInfo.of(GameState state) {
    final level = state.level;
    final locked = level != null && !Levels.isOpen(level, state.levelsCleared);
    final accent = level == null
        ? _endlessIce
        : Color(Levels.songOf(level).colors.first);
    final String caption;
    if (level == null) {
      caption = 'No finish line: survive as long as you can';
    } else if (locked) {
      caption = 'Clear level ${level - 1} to unlock it';
    } else if (level <= state.levelsCleared) {
      caption = 'Cleared! Play it again any time';
    } else {
      caption = 'Clear a level to unlock the next one';
    }
    return _PanelInfo(
      endless: level == null,
      locked: locked,
      accent: accent,
      name: level == null ? 'ENDLESS' : 'LEVEL $level',
      song: level == null
          ? 'INFINITE MODE'
          : Levels.songOf(level).name.toUpperCase(),
      caption: caption,
    );
  }

  final bool endless;
  final bool locked;
  final Color accent;
  final String name;
  final String song;
  final String caption;
}

/// How the home is laid out: the portrait stack, or the landscape one with
/// the title and the panel beside the ring
enum _Mode { stacked, sides }

/// Where the ring, the title and the panel go on a screen
class _HomeLayout {
  _HomeLayout({
    required this.mode,
    required this.center,
    required this.radius,
    required this.padding,
    this.uiScale = 1,
    this.sideWidth = 0,
  });

  /// Heights of the portrait title (from the top) and panel (from the
  /// bottom), with their margins, at uiScale 1
  static const _titleBottom = 64.0 + 34;
  static const _panelTop = 40.0 + 161;

  /// The least room the side panel keeps beside the ring (it scales down
  /// to fit)
  static const _sideRoom = 250.0;

  /// Room the ring needs above its radius (the marker) and below it (a
  /// bead), plus a little air
  static const _aboveRing = 34.0 + 6 + 10;
  static const _belowRing = 17.0 + 6;

  factory _HomeLayout.of(Size size, EdgeInsets padding) {
    // The camera fits the 720 world units square in the screen, and the
    // potato is in the middle
    final scale = min(size.width, size.height) / GameConstants.viewSize;
    final center = Offset(size.width / 2, size.height / 2);
    final full = 225 * scale;
    // Never closer to the potato than this
    final smallest = 95 * scale + 22;
    final cy = center.dy;
    // How big the ring can be with the portrait title and panel
    double stackedRadius(double u) => min(
      cy - padding.top - _titleBottom * u - _aboveRing,
      size.height - cy - padding.bottom - _panelTop * u - _belowRing,
    );
    if (stackedRadius(1) >= full) {
      return _HomeLayout(
        mode: _Mode.stacked,
        center: center,
        radius: full,
        padding: padding,
      );
    }
    // Portrait screens only ever lack a little height: a smaller ring
    // (and smaller texts on the shortest ones) makes room
    if (size.width <= size.height) {
      var u = 1.0;
      var r = stackedRadius(1);
      if (r < smallest) {
        // Shrink the texts until the smallest ring fits
        final room = size.height - padding.vertical - 2 * smallest - 60 - 50;
        u = (room / (_titleBottom + _panelTop)).clamp(0.45, 1.0);
        r = max(smallest, stackedRadius(u));
      }
      return _HomeLayout(
        mode: _Mode.stacked,
        center: center,
        radius: min(full, r),
        padding: padding,
        uiScale: u,
      );
    }
    // Up to the top bar and the bottom edge
    final vertical = min(
      cy - padding.top - 16 - _aboveRing,
      size.height - cy - padding.bottom - _belowRing,
    );
    // Leaves the panel its full width beside the ring if it can
    final horizontal =
        size.width / 2 - padding.horizontal / 2 - 12 - _sideRoom - 30;
    final r = max(smallest, min(full, min(vertical, horizontal)));
    return _HomeLayout(
      mode: _Mode.sides,
      center: center,
      radius: r,
      padding: padding,
      sideWidth: max(
        120,
        size.width / 2 - r - 30 - padding.horizontal / 2 - 12,
      ),
    );
  }

  final _Mode mode;
  final Offset center;
  final double radius;
  final EdgeInsets padding;
  final double uiScale;
  final double sideWidth;

  /// Smaller beads on a small ring, so they don't bump into each other
  double get beadScale => (radius / 110).clamp(0.7, 1.0);
}

/// The endless mode's look: fire to ice, unlike any level's single color
/// Aurora: violet to cyan
const _endlessColors = [Color(0xFF8A6BFF), Color(0xFF2FD8F0)];
final _endlessFire = _endlessColors.first;
final _endlessIce = _endlessColors.last;
final _endlessGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: _endlessColors,
);

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
      return _endless();
    }
    if (open) {
      // Cleared ones are gold, with a check badge on top
      fill = cleared
          ? GameColors.leaderboardGoldenColor
          : Color(Levels.songOf(level).colors.first);
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
      // Locked: a dim number, with a lock badge on top
      fill = Colors.white.withValues(alpha: 0.12);
      child = FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Text(
            '$level',
            style: const TextStyle(
              fontFamily: 'Cookies',
              fontSize: 16,
              color: Colors.white54,
              height: 1.1,
            ),
          ),
        ),
      );
    }
    final badge = cleared
        ? const _Badge(
            icon: Icons.check_rounded,
            color: Color(0xFF3BD16F),
            iconColor: Colors.white,
          )
        : !open
        ? const _Badge(
            icon: Icons.lock_rounded,
            color: Color(0xFF3A3150),
            iconColor: Colors.white70,
          )
        : null;
    final bead = Container(
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
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: badge == null
          ? bead
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: bead),
                // Top right: a check when cleared, a lock when locked
                Positioned(right: -3, top: -3, child: badge),
              ],
            ),
    );
  }
}

extension on _Stop {
  /// The endless mode: a fire to ice diamond, not a round bead like the
  /// levels
  Widget _endless() => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: pi / 4,
          child: FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.8,
            child: Container(
              decoration: BoxDecoration(
                gradient: _endlessGradient,
                borderRadius: BorderRadius.circular(6),
                border: selected > 0.5
                    ? Border.all(color: Colors.white, width: 2.5)
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: _endlessFire.withValues(
                      alpha: 0.35 + 0.45 * selected,
                    ),
                    blurRadius: 8 + (10 + pulse * 10) * selected,
                    offset: const Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: _endlessIce.withValues(
                      alpha: 0.35 + 0.45 * selected,
                    ),
                    blurRadius: 8 + (10 + pulse * 10) * selected,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const FractionallySizedBox(
          widthFactor: 0.62,
          heightFactor: 0.62,
          child: FittedBox(
            child: Icon(Icons.all_inclusive_rounded, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: const Color(0xFF120A1E), width: 1.5),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 10, color: iconColor),
  );
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
    this.gradient,
    required this.locked,
    required this.pulse,
    required this.onTap,
  });

  final Color accent;

  /// Instead of the plain color (the endless mode)
  final Gradient? gradient;
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
            gradient: locked ? null : gradient,
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

/// The line from each level to the next one around the ring. The steps
/// already walked (up to the next level to play) are gold.
class _LevelPathPainter extends CustomPainter {
  _LevelPathPainter({
    required this.center,
    required this.radius,
    required this.beadScale,
    required this.turn,
    required this.cleared,
    required this.intro,
  });

  final Offset center;
  final double radius;
  final double beadScale;
  final double turn;
  final int cleared;
  final double intro;

  static const _gold = GameColors.leaderboardGoldenColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (intro <= 0) {
      return;
    }
    const n = LevelSelect.stops;
    final step = 2 * pi / n;
    // Leaves room around the beads
    final gap = 21 * beadScale / radius;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var level = 1; level < Levels.count; level++) {
      // It grows in after the beads pop out
      final t = (intro * 1.6 - 0.3 - level * 0.05).clamp(0.0, 1.0);
      if (t <= 0) {
        continue;
      }
      final from = LevelSelect.stopAngle(level.toDouble()) - turn + gap;
      final sweep = (step - 2 * gap) * t;
      final walked = level <= cleared;
      final color = walked ? _gold : Colors.white;
      paint
        ..strokeWidth = walked ? 3 : 2
        ..color = color.withValues(alpha: walked ? 0.9 : 0.35);
      // Dashes
      final dash = 7 / radius;
      final space = 5 / radius;
      for (var a = 0.0; a < sweep; a += dash + space) {
        canvas.drawArc(rect, from + a, min(dash, sweep - a), false, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LevelPathPainter old) =>
      old.turn != turn ||
      old.cleared != cleared ||
      old.intro != intro ||
      old.radius != radius;
}
