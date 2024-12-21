import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ScoresLocalDataSource {
  static const _highScoreKey = 'high_score';

  ScoresLocalDataSource();

  final StreamController<int> _highScoreStreamController =
      StreamController<int>.broadcast();

  Stream<int> getHighScoreStream() => _highScoreStreamController.stream;

  Future<int?> getHighScore() async {
    final sharedPref = await SharedPreferences.getInstance();
    return sharedPref.getInt(_highScoreKey);
  }

  Future<int> setHighScore(int score) async {
    _highScoreStreamController.sink.add(score);
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setInt(_highScoreKey, score);
    return score;
  }

  Future<void> clearHighScore() async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.remove(_highScoreKey);
  }
}
