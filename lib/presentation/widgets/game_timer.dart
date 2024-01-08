import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

class GameTimer extends StatelessWidget {
  const GameTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        return FormattedGameTime(time: state.timePassed);
      },
    );
  }
}

class FormattedGameTime extends StatelessWidget {
  const FormattedGameTime({
    super.key,
    required this.time,
    this.textStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
  });

  final double time;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final seconds = (time % 60).toInt();
    final minutes = (time / 60).floor();
    return Text(
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}',
      style: textStyle,
    );
  }
}
