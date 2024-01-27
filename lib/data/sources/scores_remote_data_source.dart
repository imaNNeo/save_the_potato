import 'package:save_the_potato/domain/models/leaderboard_response_entity.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';

import 'firebase_functions_wrapper.dart';

class ScoresRemoteDataSource {
  final FirebaseFunctionsWrapper _functions;

  ScoresRemoteDataSource(this._functions);

  Future<LeaderboardResponseEntity> getLeaderboard(
    int pageLimit,
    String? pageLastId,
  ) =>
      _functions.getLeaderboard(
        pageLimit,
        pageLastId,
      );

  Future<OnlineScoreEntity> submitScore(int score) =>
      _functions.submitScore(score);

  Future<OnlineScoreEntity?> getScore() => _functions.getScore();
}
