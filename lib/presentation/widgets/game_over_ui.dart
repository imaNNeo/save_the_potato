import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'game_round_button.dart';
import 'game_timer.dart';

class GameOverUI extends StatefulWidget {
  const GameOverUI({super.key});

  @override
  State<GameOverUI> createState() => _GameOverUIState();
}

class _GameOverUIState extends State<GameOverUI>
    with SingleTickerProviderStateMixin {
  late AnimationController _gameOverAnimationController;

  @override
  void initState() {
    assert(
      context.read<GameCubit>().state.playingState.isGameOver,
      "Game must be over to show GameOverUI",
    );
    _gameOverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gameOverAnimationController.addListener(() {
      setState(() {});
    });
    _gameOverAnimationController.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        assert(state.playingState.isGameOver);
        final gameOverState = state.playingState as PlayingStateGameOver;
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: Tween<double>(begin: 0.0, end: 16.0).transform(
                  _gameOverAnimationController.value,
                ),
                sigmaY: Tween<double>(begin: 0.0, end: 16.0).transform(
                  _gameOverAnimationController.value,
                ),
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(
                  Tween<double>(begin: 0.0, end: 0.7).transform(
                    _gameOverAnimationController.value,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Game Over',
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: GameConstants.hotColors.last,
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  if (gameOverState.isHighScore) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 78.0,
                      child: Image.asset(
                        'assets/images/new-score.png',
                        color: GameColors.leaderboardGoldenColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FormattedGameTime(time: state.timePassed),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 240,
                    child: GameRoundButton(
                      title: 'TRY AGAIN!',
                      onPressed: () => context.read<GameCubit>().restartGame(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gameOverAnimationController.dispose();
    super.dispose();
  }
}
