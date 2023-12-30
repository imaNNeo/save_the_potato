import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:save_the_potato/domain/game_configs.dart';
import 'package:save_the_potato/presentation/cubit/game_cubit.dart';

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
                          color: GameConfigs.hotColors.last,
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  FormattedGameTime(time: state.timePassed),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 240,
                    child: GameRoundButton(
                      title: 'TRY AGAIN!',
                      onPressed: () => Phoenix.rebirth(context),
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
