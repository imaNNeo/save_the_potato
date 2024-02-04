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
  static const orbsMoveSpeedInitial = DoubleRange(min: 100, max: 120);
  static const orbsMoveSpeedPeak = DoubleRange(min: 190, max: 210);

  static const difficultyInitialToPeakDuration = 340.0;

  /// https://cubic-bezier.com/#.2,1.04,.38,.84
  /// Something like very vast in and very slow out
  static const difficultyInitialToPeakCurve = Cubic(0.2,1.04,0.38,0.84);

  static const double topBarPlayingOpacity = 1.0;
  static const double topBarNonPlayingOpacity = 0.2;

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

  static const String domain = 'https://savethepotato.com';
  static const String privacyPolicy = '$domain/privacy';

  static const double splashDuration = 2.0;
}