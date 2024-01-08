import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/presentation/cubit/game/game_cubit.dart';

import 'game_timer.dart';

class PotatoTopBar extends StatefulWidget {
  const PotatoTopBar({super.key});

  @override
  State<PotatoTopBar> createState() => _PotatoTopBarState();
}

class _PotatoTopBarState extends State<PotatoTopBar> {
  late SMIBool _increaseOrDecreaseInput;
  late SMINumber _fromInput;

  late GameState _previousGameState;
  double ratio = 1.0;

  double opacity = GameConstants.topBarNonPlayingOpacity;

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

        if (_previousGameState.playingState != state.playingState) {
          playingStateChanged(state.playingState);
        }

        final diff = state.heatLevel - _previousGameState.heatLevel;
        if (diff == 0) {
          _previousGameState = state;
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
      child: Opacity(
        opacity: _previousGameState.playingState.isPlaying ? 1.0 : 0.2,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const GameTimer(),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 18,
                ),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: RiveAnimation.asset(
                    'assets/rive/state-bar.riv',
                    fit: BoxFit.fitWidth,
                    onInit: _onRiveInit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void playingStateChanged(PlayingState playingState) {
    setState(() {
      opacity = playingState.isPlaying
          ? GameConstants.topBarPlayingOpacity
          : GameConstants.topBarNonPlayingOpacity;
    });
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
