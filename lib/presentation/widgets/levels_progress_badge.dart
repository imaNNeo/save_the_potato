import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';
import 'package:save_the_potato/presentation/rhythm/levels.dart';

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
