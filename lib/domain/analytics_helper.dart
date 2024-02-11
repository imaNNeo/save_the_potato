abstract class AnalyticsHelper {
  void logLevelStart(int afterGuideDurationMills);

  void logLevelEnd({
    required int durationMills,
    required bool isHighScore,
  });

  void logLevelPause(bool manually);

  void logLevelResume();

  void logLevelRestart();

  void logLogin({required String loginMethod});

  void logLeaderboardPageOpen();

  void logLeaderboardPageLoad(int durationMills);

  void logLeaderboardMyScoreClick(bool isAnonymous);

  void logShareMyScore(EventSource source);

  void logRenameNickname(EventSource source);

  void logSettingsPopupOpen();

  void logSettingsAudioChanged(bool enabled);

  void heartDisjointed();

  void heartReceived();
}

enum EventSource {
  leaderboard('leadergoard'),
  celebrateHighScore('celebrate_high_score');

  const EventSource(this.key);
  final String key;
}
