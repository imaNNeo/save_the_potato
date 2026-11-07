import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';
import 'package:save_the_potato/presentation/widgets/game_round_button.dart';
import 'package:save_the_potato/presentation/widgets/game_stroke_button.dart';

/// Shown when a level's song ends with the potato alive: the level is
/// cleared, and the next one is open
class LevelClearedUI extends StatelessWidget {
  const LevelClearedUI({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameCubit>();
    final song = Levels.songOf(level);
    final accent = Color(song.colors.first);
    final last = level >= Levels.count;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
            child: Container(color: Colors.black.withValues(alpha: 0.6 * t)),
          ),
          Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LEVEL $level',
              style: TextStyle(
                fontFamily: 'Cookies',
                fontSize: 48,
                shadows: [Shadow(blurRadius: 12, color: accent)],
              ),
            ),
            Text(
              last ? 'ALL CLEARED!' : 'CLEARED!',
              style: TextStyle(
                fontFamily: 'Cookies',
                fontSize: 28,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              song.name.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Cookies',
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 240,
              child: GameRoundButton(
                title: last ? 'HOME' : 'NEXT LEVEL',
                onPressed: () => cubit.goToLevel(last ? level : level + 1),
              ),
            ),
            const SizedBox(height: 18),
            GameStrokeButton(
              title: 'Play again',
              icon: const Icon(Icons.replay_rounded, color: Colors.white),
              onPressed: () => cubit.goToLevel(level),
            ),
          ],
        ),
      ),
    );
  }
}
