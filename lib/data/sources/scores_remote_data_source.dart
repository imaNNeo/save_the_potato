import 'package:save_the_potato/domain/models/leaderboard_entity.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';

import 'firebase_functions_wrapper.dart';

class ScoresRemoteDataSource {
  final FirebaseFunctionsWrapper _functions;

  ScoresRemoteDataSource(this._functions);

  Future<LeaderboardEntity> getLeaderboard(int pageLimit) =>
      _functions.getLeaderboard(pageLimit);

  Future<OnlineScoreEntity> submitScore(int score) =>
      _functions.submitScore(score);

  Future<OnlineScoreEntity?> getScore() => _functions.getScore();
}
