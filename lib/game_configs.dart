import 'dart:ui';

import 'package:flutter/material.dart';

class GameConfigs {
  static const int initialHeatLevel = 0;
  static const int minHeatLevel = -3;
  static const int maxHeatLevel = 3;

  static const double gameOverTimeScale = 0.1;
  static const showRetryAfterGameOverDelay = Duration(seconds: 5);
  static const showShieldLineAnimDuration = 2.0;

  static const double initialSpawnOrbsEvery = 2;
  static const double spawnOrbsEveryMinimum = 0.7;

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
}