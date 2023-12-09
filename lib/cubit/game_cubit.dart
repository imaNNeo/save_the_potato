import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/game_configs.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameState()) {
    FlameAudio.bgm.initialize();
  }

  void startGame() {
    emit(const GameState().copyWith(
      playingState: PlayingState.playing,
    ));
    // FlameAudio.bgm.play('bg.mp3');
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
    FlameAudio.bgm.stop();
  }

  void restartGame() {
    emit(const GameState().copyWith(
      playingState: PlayingState.playing,
    ));
    // FlameAudio.bgm.play('bg.mp3');
  }

  @override
  Future<void> close() async {
    super.close();
    FlameAudio.bgm.stop();
    FlameAudio.bgm.dispose();
  }
}
