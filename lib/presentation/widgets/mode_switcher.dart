import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';

/// The home screen's mode picker: a small pill with the infinite mode on
/// the left and the levels on the right. Switching to the levels pops ten
/// beads out of the potato into a ring around it, one per level: gold for
/// cleared, the song's color for the open one, dim with a lock for the
/// rest. Tapping a bead picks that level.
class ModeSwitcher extends StatefulWidget {
  const ModeSwitcher({super.key});

  /// How far the beads sit from the potato, in world units (like the
  /// shield's 68)
  static const ringRadius = 168.0;

  /// The screen angle of the bead of [level], the first one on top and
  /// going clockwise
  static double beadAngle(int level) =>
      -pi / 2 + (level - 1) * 2 * pi / Levels.count;

  @override
  State<ModeSwitcher> createState() => _ModeSwitcherState();
}

class _ModeSwitcherState extends State<ModeSwitcher>
    with TickerProviderStateMixin {
  /// 0 in the infinite mode, 1 with the bead ring out
  late final AnimationController _ring;

  /// Drives the pulse of the picked bead
  late final AnimationController _pulse;

  /// The level the levels tab goes back to
  int? _lastLevel;

  @override
  void initState() {
    super.initState();
    final levelsMode = context.read<GameCubit>().state.isLevelsMode;
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: levelsMode ? 1 : 0,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _pickInfinite(GameCubit cubit) {
    _lastLevel = cubit.state.level ?? _lastLevel;
    cubit.selectLevel(null);
  }

  void _pickLevels(GameCubit cubit) {
    final state = cubit.state;
    if (state.isLevelsMode) {
      return;
    }
    cubit.selectLevel(_lastLevel ?? Levels.nextAfter(state.levelsCleared));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameCubit>();
    return BlocConsumer<GameCubit, GameState>(
      listenWhen: (a, b) => a.level != b.level,
      listener: (context, state) {
        state.isLevelsMode ? _ring.forward() : _ring.reverse();
      },
      buildWhen: (a, b) =>
          a.level != b.level || a.levelsCleared != b.levelsCleared,
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // The camera fits the 720 world units square in the screen
            final scale =
                min(constraints.maxWidth, constraints.maxHeight) /
                GameConstants.viewSize;
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            );
            return Stack(
              children: [
                _beads(cubit, state, center, scale),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 112),
                      child: _ModePill(
                        levelsMode: state.isLevelsMode,
                        accent: Color(state.song.colors.first),
                        onInfinite: () => _pickInfinite(cubit),
                        onLevels: () => _pickLevels(cubit),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _beads(GameCubit cubit, GameState state, Offset center, double scale) {
    const beadSize = 34.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_ring, _pulse]),
      builder: (context, _) {
        final v = _ring.value;
        return IgnorePointer(
          ignoring: v < 0.5,
          child: Stack(
            children: [
              for (var level = 1; level <= Levels.count; level++)
                () {
                  // Each bead pops out a little after the one before
                  final t = (v * 1.5 - (level - 1) * 0.05).clamp(0.0, 1.0);
                  if (t <= 0) {
                    return const SizedBox();
                  }
                  final radius =
                      ModeSwitcher.ringRadius *
                      scale *
                      Curves.easeOutBack.transform(t);
                  final angle = ModeSwitcher.beadAngle(level);
                  final selected = level == state.level;
                  final size = beadSize * (selected ? 1.2 : 1.0);
                  return Positioned(
                    left: center.dx + cos(angle) * radius - size / 2,
                    top: center.dy + sin(angle) * radius - size / 2,
                    width: size,
                    height: size,
                    child: Opacity(
                      opacity: t,
                      child: _Bead(
                        level: level,
                        cleared: level <= state.levelsCleared,
                        open: Levels.isOpen(level, state.levelsCleared),
                        selected: selected,
                        pulse: _pulse.value,
                        onTap: () => cubit.selectLevel(level),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        );
      },
    );
  }
}

class _Bead extends StatelessWidget {
  const _Bead({
    required this.level,
    required this.cleared,
    required this.open,
    required this.selected,
    required this.pulse,
    required this.onTap,
  });

  final int level;
  final bool cleared;
  final bool open;
  final bool selected;
  final double pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(Levels.songOf(level).colors.first);
    final fill = cleared
        ? GameColors.leaderboardGoldenColor
        : open
        ? accent
        : Colors.white.withValues(alpha: 0.12);
    const ink = Color(0xFF120A1E);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: selected ? Border.all(color: Colors.white, width: 2.5) : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: fill.withValues(alpha: 0.8),
                    blurRadius: 14 + pulse * 10,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: cleared
            ? const Icon(Icons.check_rounded, size: 20, color: ink)
            : open
            ? Text(
                '$level',
                style: const TextStyle(
                  fontFamily: 'Cookies',
                  fontSize: 16,
                  color: ink,
                  height: 1.1,
                ),
              )
            : const Icon(Icons.lock_rounded, size: 15, color: Colors.white60),
      ),
    );
  }
}

/// Two icons in a pill, and a knob that slides to the picked one and
/// stretches while it moves
class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.levelsMode,
    required this.accent,
    required this.onInfinite,
    required this.onLevels,
  });

  final bool levelsMode;
  final Color accent;
  final VoidCallback onInfinite;
  final VoidCallback onLevels;

  static const _width = 128.0;
  static const _height = 50.0;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF120A1E);
    final knobColor = Color.lerp(accent, Colors.white, 0.2)!;
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(_height / 2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: levelsMode
                ? Alignment.centerRight
                : Alignment.centerLeft,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                width: _width / 2 - 8,
                decoration: BoxDecoration(
                  color: knobColor,
                  borderRadius: BorderRadius.circular(_height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: knobColor.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  onTap: onInfinite,
                  child: Icon(
                    Icons.all_inclusive_rounded,
                    size: 28,
                    color: levelsMode ? Colors.white : ink,
                  ),
                ),
              ),
              Expanded(
                child: _PillButton(
                  onTap: onLevels,
                  child: CustomPaint(
                    size: const Size(34, 20),
                    painter: _PathDotsPainter(levelsMode ? ink : Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(child: child),
    );
  }
}

/// Three dots stepping up and down, like stops on a road
class _PathDotsPainter extends CustomPainter {
  _PathDotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c + const Offset(-11, 4), 4, paint);
    canvas.drawCircle(c + const Offset(0, -4), 4, paint);
    canvas.drawCircle(c + const Offset(11, 4), 4, paint);
  }

  @override
  bool shouldRepaint(_PathDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Top left in the levels mode, instead of the high score: how many of the
/// levels are cleared
class LevelsProgressBadge extends StatelessWidget {
  const LevelsProgressBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GameCubit, GameState, int>(
      selector: (state) => state.levelsCleared,
      builder: (context, cleared) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 36,
                color: GameColors.leaderboardGoldenColor,
              ),
              const SizedBox(width: 6),
              Text(
                '$cleared / ${Levels.count}',
                style: const TextStyle(fontFamily: 'Cookies', fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
