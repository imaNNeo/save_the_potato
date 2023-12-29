import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:save_the_potato/presentation/cubit/game_cubit.dart';
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
                flex: 4,
                child: Container(),
              ),
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 42,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 120,
                ),
                onPressed: gameCubit.resumeGame,
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 3,
                child: Container(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameRoundButton(
                    title: 'HOME',
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Phoenix.rebirth(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
