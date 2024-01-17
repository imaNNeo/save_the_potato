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
    final currentLocalScore = await _scoresLocalDataSource.getHighScore();
    if (currentLocalScore != null) {
      final newLocalScore = switch (currentLocalScore) {
        OfflineScoreEntity() =>
          currentLocalScore.copyWith(score: scoreMilliseconds),
        OnlineScoreEntity() =>
          currentLocalScore.copyWith(score: scoreMilliseconds),
      };
      await _scoresLocalDataSource.setHighScore(newLocalScore);
    }
    final score = await _scoresRemoteDataSource.submitScore(scoreMilliseconds);
    await _scoresLocalDataSource.setHighScore(score);
    return score;
  }

  Future<ScoreEntity?> syncHighScore() async {
    final myRemoteScore = await _scoresRemoteDataSource.getScore();
    final myLocalScore = await _scoresLocalDataSource.getHighScore();

    // Both are null
    if (myRemoteScore == null && myLocalScore == null) {
      final scoreEntity = await _scoresRemoteDataSource.submitScore(0);
      await _scoresLocalDataSource.setHighScore(scoreEntity);
      return scoreEntity;
    }

    // One is null
    if (myRemoteScore == null && myLocalScore != null) {
      final newRemoteScore = await _scoresRemoteDataSource.submitScore(
        myLocalScore.score,
      );
      await _scoresLocalDataSource.setHighScore(newRemoteScore);
      return newRemoteScore;
    }

    if (myRemoteScore != null && myLocalScore == null) {
      return await _scoresLocalDataSource.setHighScore(
        myRemoteScore,
      );
    }

    // Both are not null
    if (myRemoteScore!.score == myLocalScore!.score) {
      return myRemoteScore;
    } else if (myRemoteScore.score > myLocalScore.score) {
      return await _scoresLocalDataSource.setHighScore(
        myRemoteScore,
      );
    } else {
      final newRemoteScore = await _scoresRemoteDataSource.submitScore(myLocalScore.score);
      await _scoresLocalDataSource.setHighScore(newRemoteScore);
      return newRemoteScore;
    }
  }

  Future<ScoreEntity> getHighScore() async =>
      (await _scoresLocalDataSource.getHighScore()) ?? OfflineScoreEntity(score: 0);

  Stream<ScoreEntity> getHighScoreStream() =>
      _scoresLocalDataSource.getHighScoreStream();

  Future<LeaderboardEntity> getLeaderboard(int pageLimit) =>
      _scoresRemoteDataSource.getLeaderboard(pageLimit);
}
