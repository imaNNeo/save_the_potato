import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';
import 'package:save_the_potato/cubit/game_cubit.dart';

class PotatoStateBar extends StatefulWidget {
  const PotatoStateBar({super.key});

  @override
  State<PotatoStateBar> createState() => _PotatoStateBarState();
}

class _PotatoStateBarState extends State<PotatoStateBar> {
  late SMIBool _increaseOrDecreaseInput;
  late SMINumber _fromInput;

  late GameState _previousGameState;
  double ratio = 1.0;

  @override
  void initState() {
    _previousGameState = context.read<GameCubit>().state;
    super.initState();
  }

  void _resetBarToZero() {
    _fromInput.value = -1;
    _increaseOrDecreaseInput.value = true;
  }

  @override
  Widget build(BuildContext context) {
    final width = min(600.0, max(MediaQuery.of(context).size.width / 2, 400.0));
    final height = width / (ratio * 2.2);

    return BlocListener<GameCubit, GameState>(
      listener: (context, state) {
        final shouldResetBarToZero =
            (_previousGameState.playingState.isGameOver ||
                    _previousGameState.playingState.isNone) &&
                (state.playingState.isPlaying || state.playingState.isGuide);
        if (shouldResetBarToZero) {
          assert(state.heatLevel == 0);
          _resetBarToZero();
        }

        final diff = state.heatLevel - _previousGameState.heatLevel;
        if (diff == 0) {
          return;
        }
        if (diff > 0) {
          // increased
          _fromInput.value = _previousGameState.heatLevel.toDouble();
          _increaseOrDecreaseInput.value = true;
        } else if (diff < 0) {
          // decreased
          _fromInput.value = _previousGameState.heatLevel.toDouble();
          _increaseOrDecreaseInput.value = false;
        }
        _previousGameState = state;
      },
      child: SizedBox(
        width: width,
        height: height,
        child: RiveAnimation.asset(
          'assets/rive/state-bar.riv',
          fit: BoxFit.fitWidth,
          onInit: _onRiveInit,
        ),
      ),
    );
  }

  void _onRiveInit(Artboard artBoard) {
    setState(() {
      ratio = artBoard.width / artBoard.height;
    });
    StateMachineController controller =
        StateMachineController.fromArtboard(artBoard, 'controller')!;
    artBoard.addController(controller);

    _increaseOrDecreaseInput =
        controller.findInput<bool>('isIncreased') as SMIBool;
    _fromInput = controller.findInput<double>('startState') as SMINumber;
    _resetBarToZero();
  }
}
