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

  void startGame() async {
    emit(const GameState().copyWith(
      playingState: PlayingState.guide,
    ));
  }

  void guideInteracted() async {
    if (!state.playingState.isGuide) {
      return;
    }
    emit(state.copyWith(playingState: PlayingState.playing));
    await FlameAudio.bgm.play('bg.mp3');
    await FlameAudio.bgm.audioPlayer.setVolume(GameConfigs.bgmVolume);
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

    final currentVolume = FlameAudio.bgm.audioPlayer.volume;
    const targetVolume = 0.0;
    final volumeTween = Tween<double>(
      begin: currentVolume,
      end: targetVolume,
    ).chain(CurveTween(curve: Curves.fastOutSlowIn));
    int stepCount = 30;
    final stepDelay = GameConfigs.showRetryAfterGameOverDelay ~/ stepCount;
    for (int i = 0; i < stepCount; i++) {
      await FlameAudio.bgm.audioPlayer.setVolume(
        volumeTween.transform((i + 1) / stepCount),
      );
      await Future.delayed(Duration(milliseconds: stepDelay.inMilliseconds));
    }
    await FlameAudio.bgm.audioPlayer.setVolume(targetVolume);
    emit(state.copyWith(showGameOverUI: true));
    FlameAudio.bgm.stop();
  }

  void restartGame() async {
    emit(const GameState().copyWith(
      playingState: PlayingState.guide,
    ));
  }

  @override
  Future<void> close() async {
    super.close();
    FlameAudio.bgm.stop();
    FlameAudio.bgm.dispose();
  }
}
