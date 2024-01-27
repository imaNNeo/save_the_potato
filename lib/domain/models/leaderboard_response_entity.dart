import 'package:save_the_potato/domain/models/score_entity.dart';

import 'pagination_page_data_entity.dart';

class LeaderboardResponseEntity {
  final List<OnlineScoreEntity> scores;
  final OnlineScoreEntity? myScore;
  final String leaderboardId;
  final String leaderboardTitle;
  final PaginationPageDataEntity pageData;

  LeaderboardResponseEntity({
    required this.scores,
    required this.myScore,
    required this.leaderboardId,
    required this.leaderboardTitle,
    required this.pageData,
  });

  Map<String, dynamic> toJson() => {
        'scores': scores.map((e) => e.toJson()).toList(),
        'my_score': myScore == null ? 'null' : myScore!.toJson(),
        'leaderboard_id': leaderboardId,
        'leaderboard_title': leaderboardTitle,
        'page_data': pageData.toJson(),
      };

  factory LeaderboardResponseEntity.fromJson(Map<String, dynamic> json) =>
      LeaderboardResponseEntity(
        scores: (json['scores'] as List<dynamic>)
            .map((e) => OnlineScoreEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        myScore: json['my_score'] == null
            ? null
            : OnlineScoreEntity.fromJson(json['my_score'] as Map<String, dynamic>),
        leaderboardId: json['leaderboard_id'],
        leaderboardTitle: json['leaderboard_title'],
        pageData: PaginationPageDataEntity.fromJson(
            json['page_data'] as Map<String, dynamic>),
      );

  LeaderboardResponseEntity copyWith({
    List<OnlineScoreEntity>? scores,
    OnlineScoreEntity? myScore,
    String? leaderboardId,
    String? leaderboardTitle,
    PaginationPageDataEntity? pageData,
  }) =>
      LeaderboardResponseEntity(
        scores: scores ?? this.scores,
        myScore: myScore ?? this.myScore,
        leaderboardId: leaderboardId ?? this.leaderboardId,
        leaderboardTitle: leaderboardTitle ?? this.leaderboardTitle,
        pageData: pageData ?? this.pageData,
      );
}
