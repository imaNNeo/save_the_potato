import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/game_configs.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameState());

  void startGame() {
    emit(const GameState().copyWith(
      playingState: PlayingState.playing,
    ));
  }

  void update(double dt) {
    if (!state.playingState.isPlaying) {
      return;
    }
    emit(state.copyWith(
      timePassed: state.timePassed + dt,
    ));
  }

  void potatoElementBallHit(TemperatureType type) {
    final newHeatLevel = switch (type) {
      TemperatureType.hot => state.heatLevel + 1,
      TemperatureType.cold => state.heatLevel - 1,
    };
    emit(state.copyWith(
      heatLevel: newHeatLevel,
    ));
    if (newHeatLevel <= GameConfigs.minHeatLevel ||
        newHeatLevel >= GameConfigs.maxHeatLevel) {
      _gameOver();
    }
  }

  void _gameOver() async {
    emit(state.copyWith(playingState: PlayingState.gameOver));
    await Future.delayed(GameConfigs.showRetryAfterGameOverDelay);
    emit(state.copyWith(showGameOverUI: true));
  }

  void restartGame() {
    emit(const GameState().copyWith(
      playingState: PlayingState.playing,
    ));
  }
}
