import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/presentation/components/motivation_component.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
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
    SoLoud.instance.init();
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
    emit(state.copyWith(
      firstHealthReceived: await _configsRepository.isFirstHealthReceived(),
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

  void _tryToSwitchToMultiSpawnGameMode() {
    if (state.currentGameMode is GameModeMultiSpawn) {
      return;
    }
    if (state.upcomingGameMode != null) {
      return;
    }

    // If the difficulty is too low, we don't want to switch to multi spawn yet
    if (state.difficulty < 0.5) {
      return;
    }

    // If there is a chance
    if (Random().nextDouble() > GameConstants.multiShieldGameModeChance) {
      return;
    }
    // 2 to 5
    final count = Random().nextInt(4) + 2;
    emit(state.copyWith(
      upcomingGameMode: ValueWrapper(
        GameModeMultiSpawn(spawnerSpawnCount: count),
      ),
    ));
  }

  void update(double dt) {
    if (!state.playingState.isPlaying) {
      return;
    }
    // We calculate the [state.difficulty] based on the time passed
    emit(state.copyWith(
      levelTimePassed: state.levelTimePassed + dt,
      currentGameMode: state.currentGameMode.updatePassedTime(dt),
    ));
    if (state.currentGameMode.increasesDifficulty) {
      emit(state.copyWith(
        difficultyTimePassed: state.difficultyTimePassed + dt,
      ));
    }
  }

  void potatoOrbHit() {
    var updatedGameMode = state.currentGameMode.increaseCollidedOrbsCount(
      count: 1,
    );
    updatedGameMode = updatedGameMode.resetDefendOrbStreakCount();
    emit(state.copyWith(
      healthPoints: max(0, state.healthPoints - 1),
      currentGameMode: updatedGameMode,
    ));
    if (state.healthPoints <= 0) {
      _gameOver();
      return;
    }
  }

  void onPotatoHealthPointReceived() {
    emit(state.copyWith(
      healthPoints: min(
        GameConstants.maxHealthPoints,
        state.healthPoints + 1,
      ),
      firstHealthReceived: true,
    ));
    _configsRepository.setFirstHealthReceived(true);
  }

  void _gameOver() async {
    _audioHelper.playGameOverSound();
    final score = (state.levelTimePassed * 1000).toInt();
    final previousScore = await _scoresRepository.getHighScore();
    final bool isHighScore = score > previousScore.score;
    _analyticsHelper.logLevelEnd(
      durationMills:
          (DateTime.now().millisecondsSinceEpoch - gameStartedTimestamp),
      isHighScore: isHighScore,
    );
    OnlineScoreEntity? tempOnlineScore;
    if (isHighScore && previousScore is OnlineScoreEntity) {
      tempOnlineScore = previousScore.copyWith(
        score: score,
      );
    }

    ScoreEntity highestScore;
    if (isHighScore) {
      highestScore = tempOnlineScore ?? OfflineScoreEntity(score: score);
    } else {
      highestScore = previousScore;
    }

    emit(state.copyWith(
      playingState: PlayingStateGameOver(
        score: tempOnlineScore ?? OfflineScoreEntity(score: score),
        isHighScore: isHighScore,
        highestScore: highestScore,
      ),
    ));
    _submitScore(previousScore);
    if (await _audioHelper.audioEnabled) {
      await _audioHelper.fadeAndStopBackgroundMusic(
        GameConstants.showRetryAfterGameOverDelay,
      );
    } else {
      await Future.delayed(
        GameConstants.showRetryAfterGameOverDelay,
      );
    }
    emit(state.copyWith(showGameOverUI: true));
  }

  void _submitScore(ScoreEntity previousScore) async {
    try {
      final gameConfigs = await _configsRepository.getGameConfig();
      final score = (state.levelTimePassed * 1000).toInt();
      if (score > previousScore.score) {
        final newScore = await _scoresRepository.saveScore(score);
        if (previousScore is OnlineScoreEntity &&
            newScore.rank < previousScore.rank &&
            newScore.rank <= gameConfigs.showNewScoreCelebrationRankThreshold) {
          // Let's celebrate!
          _audioHelper.playVictorySound();
          if (state.playingState is PlayingStateGameOver) {
            emit(state.copyWith(
              playingState: PlayingStateGameOver(
                score: newScore,
                isHighScore: true,
                highestScore: newScore,
              ),
            ));
          }
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
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
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

  void _playMotivationWord() {
    if (state.motivationWordsPoolToPlay.isEmpty) {
      emit(state.copyWith(
        motivationWordsPoolToPlay: MotivationWordType.values,
      ));
    }
    final randomMotivation = state.motivationWordsPoolToPlay.random();
    emit(state.copyWith(
      playMotivationWord: ValueWrapper(randomMotivation),
      motivationWordsPoolToPlay: state.motivationWordsPoolToPlay
          .where((element) => element != randomMotivation)
          .toList(),
    ));
    emit(state.copyWith(playMotivationWord: ValueWrapper.nullValue()));
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

  void onShieldHit(MovingComponent movingComponent) {
    switch (movingComponent) {
      case MovingHealth():
        break;
      case FireOrb():
      case IceOrb():
        var updatedGameMode = state.currentGameMode.increaseDefendedOrbsCount(
          count: 1,
        );
        updatedGameMode = updatedGameMode.increaseDefendOrbStreakCount(
          count: 1,
        );
        emit(state.copyWith(
          shieldHitCounter: state.shieldHitCounter + 1,
          currentGameMode: updatedGameMode,
        ));
        break;
    }

    if (state.shieldHitCounter % GameConstants.tryToSwitchGameModeEvery == 0) {
      _tryToSwitchToMultiSpawnGameMode();
    }
  }

  void multiSpawnModeSpawningFinished() {
    final showingMotivation = (state.currentGameMode as GameModeMultiSpawn)
        .shouldPlayMotivationWord();
    emit(state.copyWith(
      upcomingGameMode: ValueWrapper(GameModeSingleSpawn(
        initialDelay:
            showingMotivation ? lerpDouble(0.7, 1.7, state.difficulty)! : 0.0,
      )),
    ));
  }

  void switchToUpcomingMode() async {
    final currentGameMode = state.currentGameMode;
    bool showMotivation = false;
    if (currentGameMode is GameModeMultiSpawn) {
      if (currentGameMode.shouldPlayMotivationWord()) {
        _playMotivationWord();
        showMotivation = true;
      }
    }

    final upcoming = state.upcomingGameMode!;
    final upcomingDelay =
        showMotivation ? lerpDouble(0.80, 0.55, state.difficulty)! : 0.0;

    emit(state.copyWith(
      gameModeHistory: [
        ...state.gameModeHistory,
        state.currentGameMode,
      ],
      currentGameMode: upcoming.updateInitialDelay(
        upcoming.initialDelay + upcomingDelay,
      ),
      upcomingGameMode: const ValueWrapper(null),
    ));
  }

  @override
  Future<void> close() {
    SoLoud.instance.deinit();
    return super.close();
  }
}
