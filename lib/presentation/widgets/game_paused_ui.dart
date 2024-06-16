import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/widgets/game_round_button.dart';

class GamePausedUI extends StatelessWidget {
  const GamePausedUI({super.key});

  @override
  Widget build(BuildContext context) {
    final gameCubit = context.read<GameCubit>();
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.7),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 8,
                child: Container(),
              ),
              const Text(
                'Current Score',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              Text(
                AppUtils.getHighScoreRepresentation(
                    (gameCubit.state.levelTimePassed * 1000).toInt()),
                style: const TextStyle(
                  fontSize: 38,
                  color: Colors.white,
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(),
              ),
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 42,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 38),
              SizedBox(
                width: 300,
                child: GameRoundButton(
                  title: 'TAP TO CONTINUE',
                  onPressed: gameCubit.resumeGame,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 8,
                child: Container(),
              ),
              TextButton(
                onPressed: () => context.read<GameCubit>().restartGame(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Text(
                    'RESTART',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
