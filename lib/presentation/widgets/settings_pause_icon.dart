import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';
import 'package:save_the_potato/presentation/dialogs/base_dialog.dart';
import 'package:save_the_potato/presentation/widgets/game_icon_button.dart';

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
              PlayingStateNone() => const SizedBox(),
              PlayingStatePlaying() => GameIconButton(
                svgAssetName: 'pause.svg',
                onPressed: () => gameCubit.pauseGame(
                  manually: true,
                ),
              ),
              PlayingStatePaused() ||
              PlayingStateGameOver() ||
              PlayingStateGuide() =>
                GameIconButton(
                  svgAssetName: 'settings.svg',
                  onPressed: () => BaseDialog.showSettingsDialog(
                    context
                  ),
                ),
            },
          ),
        );
      },
    );
  }
}
