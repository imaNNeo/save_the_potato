import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game_cubit.dart';

class GamePausedUI extends StatelessWidget {
  const GamePausedUI({super.key});

  @override
  Widget build(BuildContext context) {
    final gameCubit = context.read<GameCubit>();
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.6),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
        ),
      ],
    );
  }
}
