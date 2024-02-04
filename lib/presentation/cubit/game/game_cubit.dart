import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/double_range.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/presentation/components/orb/orb_type.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';

part 'game_state.dart';
part 'playing_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit(
    this._audioHelper,
    this._scoresRepository,
    this._configsRepository,
    this._analyticsHelper,
  ) : super(const GameState()) {
    FlameAudio.bgm.initialize();
  }

  final _shieldAngleRotationAmount = pi * 1.8;

  bool isTapLeftDown = false;
  bool isTapRightDown = false;

  final AudioHelper _audioHelper;
  final ScoresRepository _scoresRepository;
  final ConfigsRepository _configsRepository;
  final AnalyticsHelper _analyticsHelper;

  late int gameShowGuideTimestamp;
  late int gameStartedTimestamp;

  void startToShowGuide() async {
    gameShowGuideTimestamp = DateTime.now().millisecondsSinceEpoch;
    emit(const GameState().copyWith(
      playingState: const PlayingStateGuide(),
    ));
  }

  void _guideInteracted() async {
    if (!state.playingState.isGuide) {
      return;
    }
    gameStartedTimestamp = DateTime.now().millisecondsSinceEpoch;
    final afterGuideDurationMills =
        gameStartedTimestamp - gameShowGuideTimestamp;
    _analyticsHelper.logLevelStart(afterGuideDurationMills);
    emit(state.copyWith(playingState: const PlayingStatePlaying()));
    _audioHelper.playBackgroundMusic();
  }

  void update(double dt) {
    if (!state.playingState.isPlaying) {
      return;
    }
    // We calculate the [state.difficulty] based on the time passed
    emit(state.copyWith(timePassed: state.timePassed + dt));
  }

  void potatoOrbHit(OrbType type) {
    switch(type) {
      case FireOrbType():
      case IceOrbType():
        emit(state.copyWith(
          healthPoints: max(0, state.healthPoints - 1),
        ));
        break;
      case HeartOrbType():
        emit(state.copyWith(
          healthPoints: min(
            GameConstants.maxHealthPoints,
            state.healthPoints + 1,
          ),
        ));
        break;
    }

    if (state.healthPoints <= 0) {
      _gameOver();
      return;
    }
  }

  void _gameOver() async {
    final score = (state.timePassed * 1000).toInt();
    final previousScore = await _scoresRepository.getHighScore();
    final bool isHighScore = score > previousScore.score;
    _analyticsHelper.logLevelEnd(
      durationMills:
          (DateTime.now().millisecondsSinceEpoch - gameStartedTimestamp),
      isHighScore: isHighScore,
    );
    emit(state.copyWith(
      playingState: PlayingStateGameOver(
        score: score,
        isHighScore: isHighScore,
      ),
    ));
    _submitScore(previousScore);
    await _fadeBackgroundVolume();
    emit(state.copyWith(showGameOverUI: true));
    FlameAudio.bgm.stop();
  }

  void _submitScore(ScoreEntity previousScore) async {
    try {
      final gameConfigs = await _configsRepository.getGameConfig();
      final score = (state.timePassed * 1000).toInt();
      if (score > previousScore.score) {
        final newScore = await _scoresRepository.saveScore(score);
        if (previousScore is OnlineScoreEntity &&
            newScore.rank < previousScore.rank &&
            newScore.rank <= gameConfigs.showNewScoreCelebrationRankThreshold) {
          // Let's celebrate!
          _audioHelper.playVictorySound();
          emit(state.copyWith(onNewHighScore: ValueWrapper(newScore)));
          emit(state.copyWith(onNewHighScore: const ValueWrapper(null)));
        }
      }
    } catch (e) {
      if (e is NetworkError) {
        // Do nothing, we don't want to show the error to the user,
        // we just retry later for example when user opens the app
      } else {
        rethrow;
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

  void pauseGame({required bool manually}) {
    if (!state.playingState.isPlaying) {
      throw StateError(
        'State is not playing, how could you call this function?',
      );
    }
    _analyticsHelper.logLevelPause(manually);
    emit(state.copyWith(playingState: const PlayingStatePaused()));
    _audioHelper.pauseBackgroundMusic();
  }

  void resumeGame() {
    _analyticsHelper.logLevelResume();
    emit(state.copyWith(playingState: const PlayingStatePlaying()));
    _audioHelper.resumeBackgroundMusic();
  }

  void restartGame() {
    _analyticsHelper.logLevelRestart();
    emit(const GameState().copyWith(
      playingState: const PlayingStateGuide(),
      restartGame: true,
    ));
    emit(state.copyWith(restartGame: false));
  }
}
