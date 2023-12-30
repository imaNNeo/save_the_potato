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
                flex: 3,
                child: Container(),
              ),
              TextButton(
                onPressed: () => Phoenix.rebirth(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Text(
                    'BACK TO HOME',
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
