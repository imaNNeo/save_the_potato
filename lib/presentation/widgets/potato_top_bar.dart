import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'game_timer.dart';
import 'life_bar.dart';

class PotatoTopBar extends StatefulWidget {
  const PotatoTopBar({super.key});

  @override
  State<PotatoTopBar> createState() => _PotatoTopBarState();
}

class _PotatoTopBarState extends State<PotatoTopBar> {
  double ratio = 1.0;

  double opacity = GameConstants.topBarNonPlayingOpacity;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (previous, current) =>
          previous.playingState != current.playingState ||
          previous.tutorial != current.tutorial,
      builder: (context, state) {
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8.0),
              AnimatedOpacity(
                opacity:
                    state.playingState is PlayingStatePlaying && !state.tutorial
                    ? 1.0
                    : 0.2,
                duration: const Duration(milliseconds: 600),
                child: const GameTimer(),
              ),
              const SizedBox(height: 4.0),
              const LifeBar(),
            ],
          ),
        );
      },
    );
  }
}
