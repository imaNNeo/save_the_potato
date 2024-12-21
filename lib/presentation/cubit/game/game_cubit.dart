import 'dart:math';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_poki_sdk/flutter_poki_sdk.dart';
import 'package:save_the_potato/domain/game_constants.dart';
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
  ) : super(const GameState());

  final _shieldAngleRotationAmount = pi * 1.8;

  bool isTapLeftDown = false;
  bool isTapRightDown = false;

  final AudioHelper _audioHelper;
  final ScoresRepository _scoresRepository;
  final ConfigsRepository _configsRepository;
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
    PokiSDK.gameplayStart();
    gameStartedTimestamp = DateTime.now().millisecondsSinceEpoch;
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
    PokiSDK.gameplayStop();
    _audioHelper.playGameOverSound();
    final score = (state.levelTimePassed * 1000).toInt();
    final previousScore = await _scoresRepository.getHighScore();
    final bool isHighScore = score > previousScore;

    int highestScore;
    if (isHighScore) {
      highestScore = score;
      _audioHelper.playVictorySound();
    } else {
      highestScore = previousScore;
    }
    await _scoresRepository.saveScore(score);

    emit(state.copyWith(
      playingState: PlayingStateGameOver(
        score: score,
        isHighScore: isHighScore,
        highestScore: highestScore,
      ),
    ));


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
    PokiSDK.gameplayStop();
    emit(state.copyWith(playingState: const PlayingStatePaused()));
    _audioHelper.pauseBackgroundMusic();
  }

  void resumeGame() {
    PokiSDK.gameplayStart();
    emit(state.copyWith(playingState: const PlayingStatePlaying()));
    _audioHelper.resumeBackgroundMusic();
  }

  void restartGame() {
    emit(const GameState().copyWith(
      playingState: const PlayingStateGuide(),
      restartGame: true,
    ));
    emit(state.copyWith(restartGame: false));
    // Todo: commercial break
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
}
