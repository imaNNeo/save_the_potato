import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';

class FirebaseAnalyticsHelper extends AnalyticsHelper {
  void _logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) {
    parameters = parameters?.map((key, value) {
      if (value is bool) {
        return MapEntry(key, value.toString());
      }
      return MapEntry(key, value);
    });
    debugPrint('AnalyticsEvent: $name, $parameters');
    FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  @override
  void logLevelStart(int afterGuideDurationMills) => _logEvent(
        name: 'level_start',
        parameters: {
          'level_name': 'main',
          'started_after_guide_duration_mills': afterGuideDurationMills,
        },
      );

  @override
  void logLevelEnd({
    required int durationMills,
    required bool isHighScore,
  }) =>
      _logEvent(
        name: 'level_end',
        parameters: {
          'level_name': 'main',
          'duration_mills': durationMills,
          'is_high_score': isHighScore,
        },
      );

  @override
  void logLevelPause(bool manually) => _logEvent(
        name: 'level_pause',
        parameters: {
          'manually': manually,
        },
      );

  @override
  void logLevelResume() => _logEvent(name: 'level_resume');

  @override
  void logLevelRestart() => _logEvent(name: 'level_restart');

  @override
  void logLogin({required String loginMethod}) => _logEvent(
        name: 'login',
        parameters: {
          'method': loginMethod,
        },
      );

  @override
  void logLeaderboardPageOpen() => _logEvent(name: 'leaderboard_page_open');

  @override
  void logLeaderboardPageLoad(int durationMills) => _logEvent(
        name: 'leaderboard_page_load',
        parameters: {
          'loading_duration_mills': durationMills,
        },
      );

  @override
  void logLeaderboardMyScoreClick(bool isAnonymous) =>
      _logEvent(name: 'leaderboard_my_score_click', parameters: {
        'is_anonymous': isAnonymous,
      });

  @override
  void logShareMyScore(
    EventSource source,
  ) =>
      _logEvent(name: 'share', parameters: {
        'content_type': 'score',
        'item_id': 'my_score',
        'method': source.key,
      });

  @override
  void logRenameNickname(
    EventSource source,
  ) =>
      _logEvent(
        name: 'rename_nickname',
        parameters: {
          'method': source.key,
        },
      );

  @override
  void logSettingsPopupOpen() => _logEvent(
        name: 'settings_opened',
      );

  @override
  void logSettingsAudioChanged(bool enabled) => _logEvent(
        name: 'settings_audio_changed',
        parameters: {
          'enabled': enabled,
        },
      );
}
