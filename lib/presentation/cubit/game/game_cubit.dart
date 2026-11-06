import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/life_meter.dart';
import 'package:save_the_potato/domain/models/errors/domain_error.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/presentation/components/motivation_component.dart';
import 'package:save_the_potato/presentation/components/moving/moving_components.dart';
import 'package:save_the_potato/presentation/cubit/game/game_mode.dart';
import 'package:save_the_potato/presentation/helpers/audio_helper.dart';
import 'package:save_the_potato/presentation/tutorial/tutorial_style.dart';

part 'game_state.dart';

part 'playing_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit(
    this._audioHelper,
    this._scoresRepository,
    this._configsRepository,
    this._analyticsHelper,
  ) : super(const GameState());

  bool isTapLeftDown = false;
  bool isTapRightDown = false;

  final AudioHelper _audioHelper;
  final ScoresRepository _scoresRepository;
  final ConfigsRepository _configsRepository;
  final AnalyticsHelper _analyticsHelper;

  late int gameShowGuideTimestamp;
  late int gameStartedTimestamp;

  /// The tutorial to run on the next start, null when the player knows
  /// the game already
  TutorialStyle? tutorialStyle;

  void startToShowGuide() async {
    gameShowGuideTimestamp = DateTime.now().millisecondsSinceEpoch;
    emit(const GameState().copyWith(playingState: const PlayingStateGuide()));
    emit(
      state.copyWith(
        firstHealthReceived: await _configsRepository.isFirstHealthReceived(),
      ),
    );
    tutorialStyle =
        TutorialStyle.forced ??
        (await _configsRepository.isTutorialDone()
            ? null
            : TutorialStyle.defaultStyle);
  }

  void _guideInteracted() async {
    if (!state.playingState.isGuide) {
      return;
    }
    if (tutorialStyle != null) {
      // Straight into the playground, the real run starts when it's done
      emit(
        state.copyWith(
          playingState: const PlayingStatePlaying(),
          tutorial: true,
        ),
      );
      return;
    }
    _startRun();
  }

  void _startRun() {
    gameStartedTimestamp = DateTime.now().millisecondsSinceEpoch;
    final afterGuideDurationMills =
        gameStartedTimestamp - gameShowGuideTimestamp;
    _analyticsHelper.logLevelStart(afterGuideDurationMills);
    emit(
      state.copyWith(
        playingState: const PlayingStatePlaying(),
        tutorial: false,
        tutorialHint: 0,
      ),
    );
    _audioHelper.playBackgroundMusic();
  }

  /// The player blocked enough orbs in the tutorial: the real run starts
  /// right where they are, with the music
  void finishTutorial() {
    if (!state.tutorial) {
      return;
    }
    tutorialStyle = null;
    _configsRepository.setTutorialDone(true);
    _startRun();
  }

  /// Points at a turn button during the tutorial (-1 left, 1 right, 0 none)
  void setTutorialHint(int direction) {
    if (state.tutorialHint != direction) {
      emit(state.copyWith(tutorialHint: direction));
    }
  }

  void update(double dt) {
    if (!state.playingState.isPlaying || state.tutorial) {
      return;
    }
    // We calculate the [state.difficulty] based on the time passed.
    // This runs every frame, so emit only once.
    emit(
      state.copyWith(
        levelTimePassed: state.levelTimePassed + dt,
        currentGameMode: state.currentGameMode.updatePassedTime(dt),
        difficultyTimePassed: state.currentGameMode.increasesDifficulty
            ? state.difficultyTimePassed + dt
            : null,
      ),
    );
  }

  void potatoOrbHit() {
    if (state.tutorial) {
      // Practice, a hit costs nothing
      return;
    }
    var updatedGameMode = state.currentGameMode.increaseCollidedOrbsCount(
      count: 1,
    );
    updatedGameMode = updatedGameMode.resetDefendOrbStreakCount();
    emit(
      state.copyWith(
        life: LifeMeter.afterMiss(state.life),
        currentGameMode: updatedGameMode,
        // A hit eases the game a little, so it stays playable
        difficultyTimePassed: max(
          0.0,
          state.difficultyTimePassed - GameConstants.difficultyRewindOnHit,
        ),
      ),
    );
    if (state.life <= 0) {
      _gameOver();
      return;
    }
  }

  void onPotatoHealthPointReceived() {
    emit(
      state.copyWith(
        life: min(1.0, state.life + 0.25),
        firstHealthReceived: true,
      ),
    );
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
      tempOnlineScore = previousScore.copyWith(score: score);
    }

    ScoreEntity highestScore;
    if (isHighScore) {
      highestScore = tempOnlineScore ?? OfflineScoreEntity(score: score);
    } else {
      highestScore = previousScore;
    }

    emit(
      state.copyWith(
        playingState: PlayingStateGameOver(
          score: tempOnlineScore ?? OfflineScoreEntity(score: score),
          isHighScore: isHighScore,
          highestScore: highestScore,
        ),
      ),
    );
    _submitScore(previousScore);
    if (await _audioHelper.audioEnabled) {
      await _audioHelper.fadeAndStopBackgroundMusic(
        GameConstants.showRetryAfterGameOverDelay,
      );
    } else {
      await Future.delayed(GameConstants.showRetryAfterGameOverDelay);
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
            emit(
              state.copyWith(
                playingState: PlayingStateGameOver(
                  score: newScore,
                  isHighScore: true,
                  highestScore: newScore,
                ),
              ),
            );
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
    _lastPressedDirection = -1;
    _guideInteracted();
    _updateShieldsTurn();
  }

  void onLeftTapUp() {
    isTapLeftDown = false;
    _updateShieldsTurn();
  }

  void onRightTapDown() {
    isTapRightDown = true;
    _lastPressedDirection = 1;
    _guideInteracted();
    _updateShieldsTurn();
  }

  void onRightTapUp() {
    isTapRightDown = false;
    _updateShieldsTurn();
  }

  /// The side pressed last wins while both are held
  int _lastPressedDirection = 0;

  void _updateShieldsTurn() {
    final int direction;
    if (isTapLeftDown && isTapRightDown) {
      direction = _lastPressedDirection;
    } else if (isTapLeftDown) {
      direction = -1;
    } else if (isTapRightDown) {
      direction = 1;
    } else {
      direction = 0;
    }
    emit(state.copyWith(shieldsTurnDirection: direction));
  }

  KeyEventResult handleKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final containsLeftArrow = keysPressed.contains(
      LogicalKeyboardKey.arrowLeft,
    );
    final containsRightArrow = keysPressed.contains(
      LogicalKeyboardKey.arrowRight,
    );
    if (containsLeftArrow || containsRightArrow) {
      _guideInteracted();
    }
    final direction = containsLeftArrow == containsRightArrow
        ? 0
        : (containsLeftArrow ? -1 : 1);
    emit(state.copyWith(shieldsTurnDirection: direction));
    return KeyEventResult.handled;
  }

  void _playMotivationWord() {
    if (state.motivationWordsPoolToPlay.isEmpty) {
      emit(
        state.copyWith(motivationWordsPoolToPlay: MotivationWordType.values),
      );
    }
    final randomMotivation = state.motivationWordsPoolToPlay.random();
    emit(
      state.copyWith(
        playMotivationWord: ValueWrapper(randomMotivation),
        motivationWordsPoolToPlay: state.motivationWordsPoolToPlay
            .where((element) => element != randomMotivation)
            .toList(),
      ),
    );
    emit(state.copyWith(playMotivationWord: ValueWrapper.nullValue()));
  }

  void pauseGame({required bool manually}) {
    if (!state.playingState.isPlaying) {
      throw StateError(
        'State is not playing, how could you call this function?',
      );
    }
    _analyticsHelper.logLevelPause(manually);
    emit(state.copyWith(playingState: const PlayingStatePaused()));
    if (!state.tutorial) {
      _audioHelper.pauseBackgroundMusic();
    }
  }

  void resumeGame() {
    _analyticsHelper.logLevelResume();
    emit(state.copyWith(playingState: const PlayingStatePlaying()));
    if (!state.tutorial) {
      _audioHelper.resumeBackgroundMusic();
    }
  }

  void restartGame() {
    _analyticsHelper.logLevelRestart();
    emit(
      const GameState().copyWith(
        playingState: const PlayingStateGuide(),
        restartGame: true,
      ),
    );
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
        final previousStage = state.lifeStage;
        emit(
          state.copyWith(
            shieldHitCounter: state.shieldHitCounter + 1,
            currentGameMode: updatedGameMode,
            life: state.playingState.isPlaying && !state.tutorial
                ? LifeMeter.afterBlock(state.life)
                : null,
          ),
        );
        if (state.lifeStage > previousStage) {
          _audioHelper.playLifeStageUpSound(state.lifeStage);
        }
        break;
    }
  }

  void multiSpawnModeSpawningFinished() {
    final showingMotivation = (state.currentGameMode as GameModeMultiSpawn)
        .shouldPlayMotivationWord();
    emit(
      state.copyWith(
        upcomingGameMode: ValueWrapper(
          GameModeSingleSpawn(
            initialDelay: showingMotivation
                ? lerpDouble(0.7, 1.7, state.difficulty)!
                : 0.0,
          ),
        ),
      ),
    );
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
    final upcomingDelay = showMotivation
        ? lerpDouble(0.80, 0.55, state.difficulty)!
        : 0.0;

    emit(
      state.copyWith(
        gameModeHistory: [...state.gameModeHistory, state.currentGameMode],
        currentGameMode: upcoming.updateInitialDelay(
          upcoming.initialDelay + upcomingDelay,
        ),
        upcomingGameMode: const ValueWrapper(null),
      ),
    );
  }
}
