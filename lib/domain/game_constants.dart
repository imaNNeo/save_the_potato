import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/models/double_range.dart';

class GameConstants {
  static const int maxHealthPoints = 3;

  static const double gameOverTimeScale = 0.1;
  static const showRetryAfterGameOverDelay = Duration(seconds: 3);
  static const showShieldLineAnimDuration = 2.0;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsSpawnEveryInitial] to [orbsSpawnEveryPeak]
  static const orbsSpawnEveryInitial = 2.5;
  static const orbsSpawnEveryPeak = 0.65;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsMoveSpeedInitial] to [orbsMoveSpeedPeak]
  static const orbsMoveSpeedInitial = DoubleRange(min: 105, max: 125);
  static const orbsMoveSpeedPeak = DoubleRange(min: 195, max: 215);

  static const difficultyInitialToPeakDuration = 300.0;

  /// https://cubic-bezier.com/#.23,1,.45,.87
  /// Something like very vast in and very slow out
  static const difficultyInitialToPeakCurve = Cubic(0.23,1.0,0.45,0.87);

  static const double topBarPlayingOpacity = 1.0;
  static const double topBarNonPlayingOpacity = 0.2;

  static const double chanceToSpawnHeart = 0.02;
  static const double chanceToSpawnHeartForFirstTime = 1.0;
  static const int spawnHeartForFirstTimeMaxCount = 3;
  static const double movingHealthPointSpeedMultiplier = 0.9;
  static double movingHealthMinSpeed = orbsMoveSpeedInitial.max;
  static double movingHealthMaxSpeed = orbsMoveSpeedPeak.min * 0.8;
  static const double bgmVolume = 0.2;

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

  static const String domain = 'https://savethepotato.com';
  static const String privacyPolicy = '$domain/privacy';

  static const double splashDuration = 2.5;
}