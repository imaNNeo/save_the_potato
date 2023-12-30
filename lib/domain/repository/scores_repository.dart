import 'package:save_the_potato/data/sources/scores_local_data_source.dart';
import 'package:save_the_potato/domain/models/high_score_bundle.dart';

class ScoresRepository {
  final ScoresLocalDataSource _scoresLocalDataSource;

  ScoresRepository(this._scoresLocalDataSource);

  Future<void> saveScore(int scoreMilliseconds) =>
      _scoresLocalDataSource.setHighScore(scoreMilliseconds);

  Future<HighScoreBundleEntity?> getHighScore() =>
      _scoresLocalDataSource.getHighScore();

  Stream<HighScoreBundleEntity> getHighScoreStream() =>
      _scoresLocalDataSource.getHighScoreStream();
}
