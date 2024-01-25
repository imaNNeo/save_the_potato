import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';

class SettingsPauseIcon extends StatelessWidget {
  const SettingsPauseIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final gameCubit = context.read<GameCubit>();
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 8.0),
            child: switch (state.playingState) {
              PlayingState.none => const SizedBox(),
              PlayingState.playing => IconButton(
                  onPressed: () => gameCubit.pauseGame(
                    manually: true,
                  ),
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
          ),
        );
      },
    );
  }
}
