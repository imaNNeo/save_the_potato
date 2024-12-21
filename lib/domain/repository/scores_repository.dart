import 'package:save_the_potato/data/sources/local/scores_local_data_source.dart';

class ScoresRepository {
  final ScoresLocalDataSource _scoresLocalDataSource;

  ScoresRepository(this._scoresLocalDataSource);

  Future<int> saveScore(int scoreMilliseconds) async {
    await _scoresLocalDataSource.setHighScore(scoreMilliseconds);
    return scoreMilliseconds;
  }

  Future<int> getHighScore() async =>
      (await _scoresLocalDataSource.getHighScore()) ?? 0;

  Stream<int> getHighScoreStream() =>
      _scoresLocalDataSource.getHighScoreStream();
}
