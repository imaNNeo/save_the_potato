import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/double_range.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit(
    this._audioHelper,
    this._scoresRepository,
  ) : super(const GameState()) {
    FlameAudio.bgm.initialize();
  }

  final _shieldAngleRotationAmount = pi * 1.8;

  bool isTapLeftDown = false;
  bool isTapRightDown = false;

  final AudioHelper _audioHelper;
  final ScoresRepository _scoresRepository;

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
    _audioHelper.playBackgroundMusic();
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
    if (newHeatLevel <= GameConstants.minHeatLevel ||
        newHeatLevel >= GameConstants.maxHeatLevel) {
      _gameOver();
    }
  }

  void _gameOver() async {
    emit(state.copyWith(playingState: PlayingState.gameOver));
    _submitScore();
    await _fadeBackgroundVolume();
    emit(state.copyWith(showGameOverUI: true));
    FlameAudio.bgm.stop();
  }

  void _submitScore() async {
    final score = (state.timePassed * 1000).toInt();
    final previousScore = await _scoresRepository.getHighScore();
    if (score > previousScore.score) {
      final newScore = await _scoresRepository.saveScore(score);
      if (previousScore is OnlineScoreEntity &&
          newScore.rank < previousScore.rank) {
        // Let's celebrate!
        _audioHelper.playVictorySound();
        emit(state.copyWith(onNewHighScore: ValueWrapper(newScore)));
        emit(state.copyWith(onNewHighScore: const ValueWrapper(null)));
      }
    }
  }

  Future<void> _fadeBackgroundVolume() async {
    final currentVolume = FlameAudio.bgm.audioPlayer.volume;
    const targetVolume = 0.0;
    final volumeTween = Tween<double>(
      begin: currentVolume,
      end: targetVolume,
    ).chain(CurveTween(curve: Curves.fastOutSlowIn));
    int stepCount = 30;
    final stepDelay = GameConstants.showRetryAfterGameOverDelay ~/ stepCount;
    for (int i = 0; i < stepCount; i++) {
      await FlameAudio.bgm.audioPlayer.setVolume(
        volumeTween.transform((i + 1) / stepCount),
      );
      await Future.delayed(Duration(milliseconds: stepDelay.inMilliseconds));
    }
    await FlameAudio.bgm.audioPlayer.setVolume(targetVolume);
  }

  void onLeftTapDown() {
    isTapLeftDown = true;
    _guideInteracted();
    _updateShieldsRotationSpeed(-_shieldAngleRotationAmount);
  }

  void onLeftTapUp() {
    isTapLeftDown = false;
    if (isTapRightDown) {
      _updateShieldsRotationSpeed(_shieldAngleRotationAmount);
    } else {
      _updateShieldsRotationSpeed(0.0);
    }
  }

  void onRightTapDown() {
    isTapRightDown = true;
    _guideInteracted();
    _updateShieldsRotationSpeed(_shieldAngleRotationAmount);
  }

  void onRightTapUp() {
    isTapRightDown = false;
    if (isTapLeftDown) {
      _updateShieldsRotationSpeed(-_shieldAngleRotationAmount);
    } else {
      _updateShieldsRotationSpeed(0.0);
    }
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

  void pauseGame() {
    emit(state.copyWith(playingState: PlayingState.paused));
    FlameAudio.bgm.pause();
  }

  void resumeGame() {
    emit(state.copyWith(playingState: PlayingState.playing));
    FlameAudio.bgm.resume();
  }

  void restartGame() {
    emit(const GameState().copyWith(
      playingState: PlayingState.guide,
      restartGame: true,
    ));
    emit(state.copyWith(restartGame: false));
  }
}
