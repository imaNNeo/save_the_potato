import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../presentation/cubit/game/game_mode.dart';

class GameConstants {
  static const double gameOverTimeScale = 0.1;
  static const showRetryAfterGameOverDelay = Duration(seconds: 3);
  static const showShieldLineAnimDuration = 2.0;

  /// It takes 8 minutes to reach the peak difficulty
  static const difficultyInitialToPeakDuration = 480.0;

  /// https://cubic-bezier.com/#.3,.5,.6,1
  /// A gentle, almost steady climb that eases off near the top:
  /// 1:00 -> 21%, 2:00 -> 40%, 3:00 -> 58%, 5:00 -> 85%, 8:00 -> 100%
  static const difficultyInitialToPeakCurve = Cubic(0.3, 0.5, 0.6, 1.0);

  /// Each time the potato gets hit, the difficulty steps back by this many
  /// seconds, so a struggling player gets a breather
  static const difficultyRewindOnHit = 20.0;

  /// How many world units fit across the shorter side of the screen. The
  /// potato, shields and orbs keep their world size, so a bigger view makes
  /// them smaller on screen and leaves more room for the orbs to travel.
  /// Was 600. On web, `?view=600` brings the old size back for comparing.
  static final double viewSize = _viewSizeFromUrl() ?? 720;

  static double? _viewSizeFromUrl() {
    if (!kIsWeb) {
      return null;
    }
    final value = double.tryParse(Uri.base.queryParameters['view'] ?? '');
    if (value == null || value < 500 || value > 1000) {
      return null;
    }
    return value;
  }

  /// Portals form this far from the potato. They scale with [viewSize] so
  /// they keep the same margin from the edge of the square.
  static double get portalMinDistance => 185 * viewSize / 600;
  static double get portalMaxDistance => 225 * viewSize / 600;

  static const double topBarPlayingOpacity = 1.0;
  static const double topBarNonPlayingOpacity = 0.2;

  static const double chanceToSpawnHeart = 0.02;
  static const double chanceToSpawnHeartForFirstTime = 1.0;
  static const int spawnHeartForFirstTimeMaxCount = 3;
  static const double movingHealthPointSpeedMultiplier = 0.9;
  static double movingHealthMinSpeed = GameModeSingleSpawn.orbsMoveSpeedInitial;
  static double movingHealthMaxSpeed =
      GameModeSingleSpawn.orbsMoveSpeedPeak * 0.8;
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

  static const String domain = 'https://savethepotato.com';
  static const String privacyPolicy = '$domain/privacy';

  static const double splashDuration = 2.5;
}
