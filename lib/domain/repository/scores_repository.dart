import 'package:save_the_potato/data/sources/scores_local_data_source.dart';
import 'package:save_the_potato/data/sources/scores_remote_data_source.dart';
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
    _scoresLocalDataSource.getHighScore();
    await _scoresLocalDataSource.setHighScore(scoreMilliseconds);
    final score = await _scoresRemoteDataSource.submitScore(scoreMilliseconds);
    return score;
  }

  Future<int?> syncHighScore() async {
    final myRemoteScore = await _scoresRemoteDataSource.getScore();
    final myLocalScore = await _scoresLocalDataSource.getHighScore();

    // Both are null
    if (myRemoteScore == null && myLocalScore == null) {
      final scoreEntity = await _scoresRemoteDataSource.submitScore(0);
      await _scoresLocalDataSource.setHighScore(scoreEntity.score);
      return scoreEntity.score;
    }

    // One is null
    if (myRemoteScore == null && myLocalScore != null) {
      await _scoresRemoteDataSource.submitScore(myLocalScore);
      return myLocalScore;
    }

    if (myRemoteScore != null && myLocalScore == null) {
      return await _scoresLocalDataSource.setHighScore(
        myRemoteScore.score,
      );
    }

    // Both are not null
    if (myRemoteScore!.score == myLocalScore!) {
      return myLocalScore;
    } else if (myRemoteScore.score > myLocalScore) {
      return await _scoresLocalDataSource.setHighScore(
        myRemoteScore.score,
      );
    } else {
      await _scoresRemoteDataSource.submitScore(myLocalScore);
      return myLocalScore;
    }
  }

  Future<int> getHighScore() async =>
      (await _scoresLocalDataSource.getHighScore()) ?? 0;

  Stream<int> getHighScoreStream() =>
      _scoresLocalDataSource.getHighScoreStream();

  Future<LeaderboardEntity> getLeaderboard() =>
      _scoresRemoteDataSource.getLeaderboard();
}
