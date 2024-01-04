import 'package:save_the_potato/data/sources/scores_local_data_source.dart';
import 'package:save_the_potato/data/sources/scores_remote_data_source.dart';
import 'package:save_the_potato/domain/models/high_score_bundle.dart';
import 'package:save_the_potato/domain/models/leaderboard_entity.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';

class ScoresRepository {
  final ScoresLocalDataSource _scoresLocalDataSource;
  final ScoresRemoteDataSource _scoresRemoteDataSource;

  ScoresRepository(
    this._scoresLocalDataSource,
    this._scoresRemoteDataSource,
  );

  Future<ScoreEntity> saveScore(int scoreMilliseconds) async {
    await _scoresLocalDataSource.setHighScore(scoreMilliseconds);
    final score = await _scoresRemoteDataSource.submitScore(scoreMilliseconds);
    return score;
  }

  Future<HighScoreBundleEntity?> syncHighScore() async {
    final myRemoteScore = await _scoresRemoteDataSource.getScore();
    final myLocalScore = await _scoresLocalDataSource.getHighScore();

    // Both are null
    if (myRemoteScore == null && myLocalScore == null) {
      return null;
    }

    // One is null
    if (myRemoteScore == null && myLocalScore != null) {
      await _scoresRemoteDataSource.submitScore(myLocalScore.highScore);
      return myLocalScore;
    }

    if (myRemoteScore != null && myLocalScore == null) {
      return await _scoresLocalDataSource.setHighScore(
        myRemoteScore.score,
      );
    }

    // Both are not null
    if (myRemoteScore!.score == myLocalScore!.highScore) {
      return myLocalScore;
    } else if (myRemoteScore.score > myLocalScore.highScore) {
      return await _scoresLocalDataSource.setHighScore(
        myRemoteScore.score,
      );
    } else {
      await _scoresRemoteDataSource.submitScore(myLocalScore.highScore);
      return myLocalScore;
    }
  }

  Stream<HighScoreBundleEntity> getHighScoreStream() =>
      _scoresLocalDataSource.getHighScoreStream();

  Future<LeaderboardEntity> getLeaderboard() =>
      _scoresRemoteDataSource.getLeaderboard();
}
