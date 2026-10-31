import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'autopilot.dart';
import 'boss.dart';
import 'levels.dart';
import 'missions.dart';
import 'perks.dart';
import 'proto_events.dart';
import 'prototypes.dart';
import 'themes.dart';

/// The Flutter side of the prototypes: menus, panels and small HUD bits,
/// drawn on top of the game. Only the active prototype's part is built.
class PrototypeOverlay extends StatelessWidget {
  const PrototypeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (a, b) =>
          a.playingState != b.playingState ||
          a.showGameOverUI != b.showGameOverUI,
      builder: (context, state) => switch (Prototypes.active) {
        Prototype.themes => _ThemesOverlay(state: state),
        Prototype.perks => _PerksOverlay(state: state),
        Prototype.levels => _LevelsOverlay(state: state),
        Prototype.missions => _MissionsOverlay(state: state),
        Prototype.coop => const SizedBox(),
        Prototype.boss => const _BossBar(),
        Prototype.none => const SizedBox(),
      },
    );
  }
}

/// Runs [action] once after [delay] when the autopilot plays, for menus
mixin _BotTimer<T extends StatefulWidget> on State<T> {
  Timer? _botTimer;

  void botAfter(Duration delay, VoidCallback action) {
    if (!Prototypes.autopilot) {
      return;
    }
    _botTimer?.cancel();
    _botTimer = Timer(delay, () {
      if (mounted) action();
    });
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }
}

const _panelColor = Color(0xE6101028);

Widget _panel({required Widget child, EdgeInsets? padding}) => Container(
  padding: padding ?? const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: _panelColor,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.white24),
  ),
  child: child,
);

// ---------------------------------------------------------------------------
// 1. Themes

class _ThemesOverlay extends StatefulWidget {
  const _ThemesOverlay({required this.state});

  final GameState state;

  @override
  State<_ThemesOverlay> createState() => _ThemesOverlayState();
}

class _ThemesOverlayState extends State<_ThemesOverlay> with _BotTimer {
  /// The autopilot changes the theme every other visit to the menu
  static bool _botChangedTheme = false;
  static final double _cycle = Prototypes.number('cycle') ?? 14;
  int? _denied;

  @override
  void initState() {
    super.initState();
    final sparks = Prototypes.number('sparks');
    if (sparks != null && ShieldThemes.sparks == 140) {
      ShieldThemes.sparks = sparks.toInt();
    }
    _onState();
  }

  @override
  void didUpdateWidget(covariant _ThemesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.playingState != widget.state.playingState) {
      _onState();
    }
  }

  void _onState() {
    final playing = widget.state.playingState;
    Autopilot.holdOnGuide = playing.isGuide && !_botChangedTheme;
    if (playing.isGuide && !_botChangedTheme) {
      botAfter(const Duration(milliseconds: 1400), () {
        _botChangedTheme = true;
        _select((ShieldThemes.selectedIndex + 1) % ShieldThemes.all.length);
      });
    } else if (playing.isGuide) {
      _botChangedTheme = false;
    } else if (playing.isPlaying) {
      botAfter(Duration(milliseconds: (_cycle * 1000).toInt()), () {
        final cubit = context.read<GameCubit>();
        ShieldThemes.sparks += cubit.state.levelTimePassed.floor();
        cubit.restartGame();
      });
    } else if (playing.isGameOver) {
      botAfter(const Duration(seconds: 5), () {
        context.read<GameCubit>().restartGame();
      });
    }
  }

  void _select(int index) {
    if (!ShieldThemes.tryUnlock(index)) {
      setState(() => _denied = index);
      Autopilot.holdOnGuide = false;
      return;
    }
    ShieldThemes.selectedIndex = index;
    // The shields and orbs read their colors when they load
    context.read<GameCubit>().restartGame();
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.state.playingState;
    if (playing.isGameOver && widget.state.showGameOverUI) {
      return Align(
        alignment: const Alignment(0, 0.7),
        child: _sparksChip('+${widget.state.levelTimePassed.floor()}')
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut),
      );
    }
    if (!playing.isGuide) {
      return const SizedBox();
    }
    return SafeArea(
      child: Align(
        alignment: const Alignment(0, 0.42),
        child: _panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sparksChip('${ShieldThemes.sparks}'),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < ShieldThemes.all.length; i++) _swatch(i),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sparksChip(String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFFFFD84D),
        size: 22,
      ),
      const SizedBox(width: 6),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFFFFD84D),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _swatch(int index) {
    final theme = ShieldThemes.all[index];
    final selected = ShieldThemes.selectedIndex == index;
    final unlocked = ShieldThemes.isUnlocked(index);
    Widget swatch = GestureDetector(
      onTap: () => _select(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 3 : 1.5,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: theme.fire[1], blurRadius: 14)]
                    : null,
              ),
              child: Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: CustomPaint(painter: _SwatchPainter(theme)),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: unlocked
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: Colors.white60,
                        ),
                        Text(
                          '${theme.cost}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
    if (selected) {
      swatch = swatch
          .animate(key: ValueKey('sel$index'))
          .scale(
            begin: const Offset(0.7, 0.7),
            duration: 500.ms,
            curve: Curves.elasticOut,
          );
    }
    if (_denied == index) {
      swatch = swatch.animate(key: UniqueKey()).shakeX(hz: 6, amount: 4);
    }
    return swatch;
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.theme);

  final ShieldTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawCircle(rect.center, size.width / 2, Paint()..color = theme.sky);
    final arc = rect.deflate(5);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arc,
      -pi * 0.95,
      pi * 0.7,
      false,
      stroke..color = theme.fire[1],
    );
    canvas.drawArc(
      arc,
      pi * 0.05,
      pi * 0.7,
      false,
      stroke..color = theme.ice[1],
    );
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter old) => old.theme != theme;
}

// ---------------------------------------------------------------------------
// 2. Perks

class _PerksOverlay extends StatefulWidget {
  const _PerksOverlay({required this.state});

  final GameState state;

  @override
  State<_PerksOverlay> createState() => _PerksOverlayState();
}

class _PerksOverlayState extends State<_PerksOverlay> with _BotTimer {
  final run = PerkRun.instance;
  Perk? _pressed;

  @override
  void initState() {
    super.initState();
    run.addListener(_onRun);
  }

  @override
  void dispose() {
    run.removeListener(_onRun);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PerksOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.playingState.isGameOver &&
        !oldWidget.state.playingState.isGameOver) {
      botAfter(const Duration(seconds: 5), () {
        context.read<GameCubit>().restartGame();
      });
    }
  }

  void _onRun() {
    setState(() {});
    if (run.offer.isNotEmpty) {
      // The autopilot likes the perks it has the fewest of
      final choice = [...run.offer]
        ..sort((a, b) => run.count(a).compareTo(run.count(b)));
      botAfter(const Duration(milliseconds: 1700), () => _pick(choice.first));
    }
  }

  void _pick(Perk perk) async {
    if (_pressed != null) {
      return;
    }
    setState(() => _pressed = perk);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final cubit = context.read<GameCubit>();
    run.pick(perk);
    _pressed = null;
    ProtoEvents.unfreeze(cubit);
    if (perk == Perk.extraHeart) {
      cubit.onPotatoHealthPointReceived();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.state.playingState;
    final children = <Widget>[];
    if (!playing.isGuide && run.picked.isNotEmpty) {
      children.add(
        SafeArea(
          child: Align(
            alignment: const Alignment(0, 0.97),
            child: Wrap(
              spacing: 6,
              children: [
                for (final perk in Perk.values)
                  if (run.count(perk) > 0) _perkChip(perk),
              ],
            ),
          ),
        ),
      );
    }
    if (run.offer.isNotEmpty && playing.isPaused) {
      children.add(_draft());
    }
    return Stack(children: children);
  }

  Widget _perkChip(Perk perk) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _panelColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: perk.color.withValues(alpha: 0.6)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(perk.icon, color: perk.color, size: 18),
        if (run.count(perk) > 1)
          Text(
            ' ×${run.count(perk)}',
            style: TextStyle(color: perk.color, fontWeight: FontWeight.bold),
          ),
      ],
    ),
  );

  Widget _draft() {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, perk) in run.offer.indexed)
            _card(perk)
                .animate(delay: (i * 120).ms)
                .slideY(begin: 0.6, duration: 350.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 200.ms),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _card(Perk perk) {
    final pressed = _pressed == perk;
    final dimmed = _pressed != null && !pressed;
    final owned = run.count(perk);
    return GestureDetector(
      onTap: () => _pick(perk),
      child: AnimatedScale(
        scale: pressed ? 1.15 : (dimmed ? 0.85 : 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.3 : 1,
          duration: const Duration(milliseconds: 250),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: 96,
            height: 132,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  perk.color.withValues(alpha: 0.35),
                  const Color(0xFF14142E),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: pressed ? Colors.white : perk.color,
                width: pressed ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: perk.color.withValues(alpha: pressed ? 0.9 : 0.4),
                  blurRadius: pressed ? 24 : 12,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(perk.icon, color: perk.color, size: 52),
                const SizedBox(height: 12),
                // One pip per copy you will own after picking it
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i <= owned; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == owned ? Colors.white : perk.color,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Levels

class _LevelsOverlay extends StatefulWidget {
  const _LevelsOverlay({required this.state});

  final GameState state;

  @override
  State<_LevelsOverlay> createState() => _LevelsOverlayState();
}

class _LevelsOverlayState extends State<_LevelsOverlay> with _BotTimer {
  final levels = Levels.instance;

  /// The map shows on every visit to the menu, until a level is picked
  static bool _mapOpen = true;

  /// The autopilot plays the first level, then skips to a later one
  static final _botPlan = <int>[0, 8];
  static int _botStep = 0;
  int? _tapped;

  @override
  void initState() {
    super.initState();
    levels.addListener(_onLevels);
    _onState();
  }

  @override
  void dispose() {
    levels.removeListener(_onLevels);
    super.dispose();
  }

  void _onLevels() => setState(() {});

  @override
  void didUpdateWidget(covariant _LevelsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.playingState != widget.state.playingState) {
      _onState();
    }
  }

  void _onState() {
    final playing = widget.state.playingState;
    Autopilot.holdOnGuide = playing.isGuide && _mapOpen;
    if (playing.isGuide && _mapOpen) {
      final next = _botPlan[min(_botStep, _botPlan.length - 1)];
      botAfter(const Duration(milliseconds: 2200), () {
        _botStep++;
        if (!levels.isOpen(next)) {
          levels.unlockUpTo(next);
        }
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _open(next);
        });
      });
    }
    if (playing.isPaused && levels.result != null) {
      botAfter(const Duration(milliseconds: 3200), _toMap);
    }
    if (playing.isGameOver) {
      botAfter(const Duration(seconds: 5), _toMap);
    }
  }

  void _open(int index) async {
    if (!levels.isOpen(index)) {
      return;
    }
    setState(() => _tapped = index);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    levels.select(index);
    setState(() {
      _tapped = null;
      _mapOpen = false;
    });
    Autopilot.holdOnGuide = false;
  }

  void _toMap() {
    _mapOpen = true;
    levels.result = null;
    ProtoHooks.frozen = false;
    context.read<GameCubit>().restartGame();
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.state.playingState;
    if (playing.isGuide && _mapOpen) {
      return _map();
    }
    if (playing.isPlaying || (playing.isPaused && levels.result != null)) {
      return Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.78),
              child: _progress(),
            ),
          ),
          if (levels.result != null) _result(levels.result!),
        ],
      );
    }
    if (playing.isGuide) {
      return SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.62),
          child: _levelBadge(levels.current, big: true),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _levelBadge(int index, {bool big = false}) {
    final size = big ? 64.0 : 44.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFB13D), Color(0xFFFF5900)],
        ),
        border: Border.all(color: Colors.white, width: big ? 3 : 2),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: big ? 28 : 18,
        ),
      ),
    );
  }

  Widget _progress() {
    return StreamBuilder<GameState>(
      stream: context.read<GameCubit>().stream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.state;
        final level = levels.level;
        final ratio = (state.levelTimePassed / level.seconds).clamp(0.0, 1.0);
        return SizedBox(
          width: 220,
          child: Row(
            children: [
              _levelBadge(levels.current),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFFB13D),
                        ),
                      ),
                    ),
                    // Wave markers
                    for (final (at, _) in level.waves)
                      Positioned(
                        left: (at / level.seconds) * 148 - 6,
                        top: -3,
                        child: const Icon(
                          Icons.waves_rounded,
                          size: 16,
                          color: Color(0xFFFF63B4),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.flag_rounded, color: Colors.white),
            ],
          ),
        );
      },
    );
  }

  Widget _stars(int count, {double size = 14}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Icon(
          Icons.star_rounded,
          size: size,
          color: i < count ? const Color(0xFFFFD84D) : Colors.white24,
        ),
    ],
  );

  Widget _map() {
    // A winding path of nodes, three per row, snaking down
    final nodes = <Widget>[];
    for (var row = 0; row < 4; row++) {
      final cells = <Widget>[];
      for (var col = 0; col < 3; col++) {
        final index = row * 3 + (row.isEven ? col : 2 - col);
        cells.add(_node(index));
      }
      nodes.add(
        Row(mainAxisAlignment: MainAxisAlignment.center, children: cells),
      );
    }
    return Container(
      color: Colors.black45,
      child: SafeArea(
        child: Center(
          child: _panel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD84D)),
                    Text(
                      ' ${levels.totalStars} / ${Levels.all.length * 3}',
                      style: const TextStyle(
                        color: Color(0xFFFFD84D),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...nodes,
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _node(int index) {
    final open = levels.isOpen(index);
    final stars = levels.stars[index];
    final isNext = open && stars == 0;
    Widget badge = Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: open
            ? RadialGradient(
                colors: stars > 0
                    ? const [Color(0xFF7FD4FF), Color(0xFF0063BE)]
                    : const [Color(0xFFFFB13D), Color(0xFFFF5900)],
              )
            : null,
        color: open ? null : Colors.white10,
        border: Border.all(
          color: _tapped == index ? Colors.white : Colors.white38,
          width: _tapped == index ? 3 : 1.5,
        ),
      ),
      child: open
          ? Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : const Icon(Icons.lock_rounded, color: Colors.white38, size: 20),
    );
    if (isNext) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(end: const Offset(1.1, 1.1), duration: 600.ms);
    }
    if (_tapped == index) {
      badge = badge.animate().scale(
        end: const Offset(1.3, 1.3),
        duration: 300.ms,
        curve: Curves.easeOutBack,
      );
    }
    return GestureDetector(
      onTap: () => _open(index),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [badge, const SizedBox(height: 3), _stars(stars)],
        ),
      ),
    );
  }

  Widget _result(int stars) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: _panel(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _levelBadge(levels.current, big: true),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                        Icons.star_rounded,
                        size: i == 1 ? 72 : 56,
                        color: i < stars
                            ? const Color(0xFFFFD84D)
                            : Colors.white24,
                      )
                      .animate(delay: (300 + i * 300).ms)
                      .scale(
                        begin: const Offset(0, 0),
                        duration: 450.ms,
                        curve: Curves.elasticOut,
                      ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  iconSize: 32,
                  onPressed: _toMap,
                  icon: const Icon(Icons.grid_view_rounded),
                ),
              ],
            ),
          ],
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Missions

class _MissionsOverlay extends StatefulWidget {
  const _MissionsOverlay({required this.state});

  final GameState state;

  @override
  State<_MissionsOverlay> createState() => _MissionsOverlayState();
}

class _MissionsOverlayState extends State<_MissionsOverlay> with _BotTimer {
  final missions = Missions.instance;
  Mission? _toast;
  Timer? _toastTimer;
  int _levelAtRunStart = Missions.instance.potatoLevel;
  int _xpAtRunStart = Missions.instance.xp;

  @override
  void initState() {
    super.initState();
    missions.addListener(_onMissions);
    _onState();
  }

  @override
  void dispose() {
    missions.removeListener(_onMissions);
    _toastTimer?.cancel();
    super.dispose();
  }

  void _onMissions() {
    final finished = missions.justFinished;
    if (finished != null) {
      missions.justFinished = null;
      _toast = finished;
      _toastTimer?.cancel();
      _toastTimer = Timer(const Duration(milliseconds: 2200), () {
        if (mounted) setState(() => _toast = null);
      });
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _MissionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.playingState != widget.state.playingState) {
      _onState();
    }
  }

  void _onState() {
    final playing = widget.state.playingState;
    if (playing.isGuide) {
      _levelAtRunStart = missions.potatoLevel;
      _xpAtRunStart = missions.xp;
      Autopilot.holdOnGuide = true;
      // Show what was done last run for a moment, then swap in new missions
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) missions.refill();
      });
      botAfter(const Duration(milliseconds: 2600), () {
        Autopilot.holdOnGuide = false;
      });
    }
    if (playing.isGameOver) {
      botAfter(const Duration(seconds: 7), () {
        context.read<GameCubit>().restartGame();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.state.playingState;
    final children = <Widget>[];
    if (playing.isGuide) {
      children.add(
        SafeArea(
          child: Align(
            alignment: const Alignment(0, -0.55),
            child: _panel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _levelBar(),
                  const SizedBox(height: 12),
                  for (final m in missions.active) _missionRow(m, wide: true),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (playing.isPlaying || playing.isPaused) {
      children.add(
        SafeArea(
          child: Align(
            alignment: const Alignment(-0.97, -0.55),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final m in missions.active) _missionRow(m)],
            ),
          ),
        ),
      );
    } else if (playing.isGameOver && widget.state.showGameOverUI) {
      children.add(
        Align(
          alignment: const Alignment(0, 0.82),
          child: _panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final m in missions.finishedThisRun)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(m.kind.icon, color: m.kind.color),
                      ),
                  ],
                ),
                if (missions.finishedThisRun.isNotEmpty)
                  const SizedBox(height: 8),
                _levelBar(animateFromRunStart: true),
              ],
            ),
          ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
        ),
      );
    }
    if (_toast != null && playing.isPlaying) {
      children.add(
        SafeArea(
          child:
              Align(
                    alignment: const Alignment(0, -0.42),
                    child: _panel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _toast!.kind.icon,
                            color: _toast!.kind.color,
                            size: 28,
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF3CCE1F),
                            size: 28,
                          ),
                          Text(
                            '  +${_toast!.xp}',
                            style: const TextStyle(
                              color: Color(0xFF9CFF6B),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(key: ObjectKey(_toast))
                  .scale(duration: 400.ms, curve: Curves.elasticOut)
                  .then(delay: 1400.ms)
                  .fadeOut(duration: 300.ms),
        ),
      );
    }
    return IgnorePointer(child: Stack(children: children));
  }

  Widget _levelBar({bool animateFromRunStart = false}) {
    final level = missions.potatoLevel;
    final ratio = missions.levelRatio;
    final bar = SizedBox(
      width: 200,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFE9B0), Color(0xFFE8A33A)],
              ),
            ),
            child: Text(
              '$level',
              style: const TextStyle(
                color: Color(0xFF3A2200),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: animateFromRunStart
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: level > _levelAtRunStart
                            ? 0
                            : _xpAtRunStart / Missions.xpPerLevel,
                        end: ratio,
                      ),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => _xpBar(v),
                    )
                  : _xpBar(ratio),
            ),
          ),
        ],
      ),
    );
    if (animateFromRunStart && level > _levelAtRunStart) {
      return bar
          .animate(delay: 300.ms)
          .shimmer(duration: 900.ms, color: Colors.white)
          .scale(
            begin: const Offset(1.15, 1.15),
            duration: 500.ms,
            curve: Curves.elasticOut,
          );
    }
    return bar;
  }

  Widget _xpBar(double v) => LinearProgressIndicator(
    value: v,
    minHeight: 10,
    backgroundColor: Colors.white12,
    valueColor: const AlwaysStoppedAnimation(Color(0xFF9CFF6B)),
  );

  Widget _missionRow(Mission m, {bool wide = false}) {
    final done = m.done;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: wide
          ? null
          : BoxDecoration(
              color: _panelColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: done ? const Color(0xFF3CCE1F) : Colors.white24,
              ),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(m.kind.icon, color: m.kind.color, size: wide ? 24 : 22),
          const SizedBox(width: 6),
          SizedBox(
            width: wide ? 110 : 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: m.ratio,
                minHeight: wide ? 8 : 7,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(
                  done ? const Color(0xFF3CCE1F) : m.kind.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (done)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF3CCE1F),
              size: 18,
            )
          else
            Text(
              wide ? '${m.progress} / ${m.goal}' : '${m.progress}/${m.goal}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: wide ? 14 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (wide) ...[
            const SizedBox(width: 10),
            Text(
              '+${m.xp}',
              style: const TextStyle(color: Color(0xFF9CFF6B), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Boss

class _BossBar extends StatelessWidget {
  const _BossBar();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.8),
          child: ValueListenableBuilder<double?>(
            valueListenable: BossFight.hp,
            builder: (context, hp, _) {
              if (hp == null) {
                return const SizedBox();
              }
              return SizedBox(
                width: 220,
                child: Row(
                  children: [
                    const Icon(
                      Icons.brightness_6_rounded,
                      color: Color(0xFFFF2E6B),
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: hp,
                          minHeight: 12,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFFF2E6B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms);
            },
          ),
        ),
      ),
    );
  }
}
