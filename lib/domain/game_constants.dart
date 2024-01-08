import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/models/double_range.dart';

class GameConstants {
  static const int initialHeatLevel = 0;
  static const int minHeatLevel = -3;
  static const int maxHeatLevel = 3;

  static const double gameOverTimeScale = 0.1;
  static const showRetryAfterGameOverDelay = Duration(seconds: 3);
  static const showShieldLineAnimDuration = 2.0;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsSpawnEveryInitial] to [orbsSpawnEveryPeak]
  static const orbsSpawnEveryInitial = 2.5;
  static const orbsSpawnEveryPeak = 0.6;

  /// It takes [difficultyInitialToPeakDuration] seconds to
  /// go from [orbsMoveSpeedInitial] to [orbsMoveSpeedPeak]
  static const orbsMoveSpeedInitial = DoubleRange(min: 100, max: 120);
  static const orbsMoveSpeedPeak = DoubleRange(min: 200, max: 220);

  static const difficultyInitialToPeakDuration = 240.0;

  static const double topBarPlayingOpacity = 1.0;
  static const double topBarNonPlayingOpacity = 0.2;

  static const double bgmVolume = 0.2;

  static const heatGradientFrom = Color(0xFF290101);
  static const neutralGradientFrom = Color(0xFF141414);
  static const coldGradientFrom = Color(0xFF002140);

  static const hotColors = [
    Color(0xFFFF9362),
    Color(0xFFFF5900),
    Color(0xFFFF2F00),
  ];

  static const coldColors = [
    Color(0xFFB4E6FF),
    Color(0xFF00AFFF),
    Color(0xFF008BFF),
  ];

  static const String domain = 'https://savethepotato.com';
  static const String privacyPolicy = '$domain/privacy';

  static const double splashDuration = 2.0;
}