import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/game_configs.dart';
import 'package:save_the_potato/models/double_range.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameState()) {
    FlameAudio.bgm.initialize();
  }

  final _shieldAngleRotationAmount = pi * 1.8;

  void startGame() async {
    emit(const GameState().copyWith(
      playingState: PlayingState.guide,
    ));
  }

  void _guideInteracted() async {
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
    // We calculate the [state.difficulty] based on the time passed
    emit(state.copyWith(timePassed: state.timePassed + dt));
  }

  void potatoOrbHit(TemperatureType type) {
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

  void onLeftTapDown() {
    _guideInteracted();
    _updateShieldsRotationSpeed(-_shieldAngleRotationAmount);
  }

  void onLeftTapUp() {
    if (state.shieldsAngleRotationSpeed == _shieldAngleRotationAmount) {
      return;
    }
    _updateShieldsRotationSpeed(0.0);
  }

  void onRightTapDown() {
    _guideInteracted();
    _updateShieldsRotationSpeed(_shieldAngleRotationAmount);
  }

  void onRightTapUp() {
    if (state.shieldsAngleRotationSpeed == -_shieldAngleRotationAmount) {
      return;
    }
    _updateShieldsRotationSpeed(0.0);
  }

  KeyEventResult handleKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final containsLeftArrow = keysPressed.contains(
      LogicalKeyboardKey.arrowLeft,
    );
    final containsRightArrow = keysPressed.contains(
      LogicalKeyboardKey.arrowRight,
    );
    if (containsLeftArrow || containsRightArrow) {
      _guideInteracted();
    }
    var rotationSpeed = 0.0;

    if (containsLeftArrow && containsRightArrow) {
      _updateShieldsRotationSpeed(0.0);
      return KeyEventResult.handled;
    }

    if (!containsLeftArrow && !containsRightArrow) {
      _updateShieldsRotationSpeed(0.0);
      return KeyEventResult.handled;
    }

    if (containsLeftArrow) {
      rotationSpeed -= _shieldAngleRotationAmount;
    }

    if (containsRightArrow) {
      rotationSpeed += _shieldAngleRotationAmount;
    }

    if (rotationSpeed != 0) {
      _updateShieldsRotationSpeed(rotationSpeed);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _updateShieldsRotationSpeed(double speed) {
    emit(state.copyWith(
      shieldsAngleRotationSpeed: speed.clamp(
        -_shieldAngleRotationAmount,
        _shieldAngleRotationAmount,
      ),
    ));
  }
}
