import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ice_fire_game/game_configs.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameState());

  void startGame() {
    emit(state.copyWith(
      playingState: PlayingState.playing,
      startTimeStamp: DateTime.now().millisecondsSinceEpoch,
      heatLevel: GameConfigs.initialHeatLevel,
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
    emit(const GameState());
    startGame();
  }
}
