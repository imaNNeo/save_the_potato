import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';

class TopLeftIcon extends StatelessWidget {
  const TopLeftIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final gameCubit = context.read<GameCubit>();
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: switch (state.playingState) {
            PlayingState.none => const SizedBox(),
            PlayingState.playing => IconButton(
                onPressed: gameCubit.pauseGame,
                icon: const Icon(
                  Icons.pause,
                  size: 36,
                ),
              ),
            PlayingState.paused ||
            PlayingState.gameOver ||
            PlayingState.guide =>
              IconButton(
                onPressed: () => BaseDialog.showSettingsDialog(context),
                icon: const Icon(
                  Icons.settings,
                  size: 36,
                ),
              ),
          },
        );
      },
    );
  }
}
