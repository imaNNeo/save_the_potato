import 'package:flutter/material.dart';

import '../presentation/cubit/game/game_mode.dart';

class GameConstants {
  static const int maxHealthPoints = 3;

  static const double gameOverTimeScale = 0.1;
  static const showRetryAfterGameOverDelay = Duration(seconds: 3);
  static const showShieldLineAnimDuration = 2.0;

  static const difficultyInitialToPeakDuration = 300.0;
  static int tryToSwitchGameModeEvery = 3;
  static const multiShieldGameModeChance = 0.10;

  /// https://cubic-bezier.com/#.23,1,.45,.87
  /// Something like very vast in and very slow out
  static const difficultyInitialToPeakCurve = Cubic(0.23,1.0,0.45,0.87);

  static const double topBarPlayingOpacity = 1.0;
  static const double topBarNonPlayingOpacity = 0.2;

  static const double chanceToSpawnHeart = 0.02;
  static const double chanceToSpawnHeartForFirstTime = 1.0;
  static const int spawnHeartForFirstTimeMaxCount = 3;
  static const double movingHealthPointSpeedMultiplier = 0.9;
  static double movingHealthMinSpeed = GameModeSingleSpawn.orbsMoveSpeedInitial;
  static double movingHealthMaxSpeed = GameModeSingleSpawn.orbsMoveSpeedPeak * 0.8;
  static const double bgmVolume = 4.0;
  static const double soundEffectsVolume = 7.0;

  static const redColors = [
    Color(0xFFFF9362),
    Color(0xFFFF5900),
    Color(0xFFFF2F00),
  ];

  static const blueColors = [
    Color(0xFFB4E6FF),
    Color(0xFF00AFFF),
    Color(0xFF008BFF),
  ];

  static const pinkColors = [
    Color(0xFFFFB4CE),
    Color(0xFFFF639F),
    Color(0xFFFF006A),
  ];

  static const double splashDuration = 2.5;
}