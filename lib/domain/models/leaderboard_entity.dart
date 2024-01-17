import 'package:save_the_potato/domain/models/score_entity.dart';

import 'pagination_page_data_entity.dart';

class LeaderboardEntity {
  final List<OnlineScoreEntity> scores;
  final OnlineScoreEntity? myScore;
  final String leaderboardId;
  final String leaderboardTitle;
  final PaginationPageDataEntity pageData;

  LeaderboardEntity({
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

  factory LeaderboardEntity.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntity(
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

  LeaderboardEntity copyWith({
    List<OnlineScoreEntity>? scores,
    OnlineScoreEntity? myScore,
    String? leaderboardId,
    String? leaderboardTitle,
    PaginationPageDataEntity? pageData,
  }) =>
      LeaderboardEntity(
        scores: scores ?? this.scores,
        myScore: myScore ?? this.myScore,
        leaderboardId: leaderboardId ?? this.leaderboardId,
        leaderboardTitle: leaderboardTitle ?? this.leaderboardTitle,
        pageData: pageData ?? this.pageData,
      );
}
