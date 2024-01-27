import 'package:equatable/equatable.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';

sealed class LeaderboardScoreItem {}

class LeaderboardLoadedScoreItem extends LeaderboardScoreItem
    with EquatableMixin {
  final OnlineScoreEntity score;
  final bool refreshing;

  LeaderboardLoadedScoreItem({
    required this.score,
    this.refreshing = false,
  });

  LeaderboardLoadedScoreItem copyWith({
    OnlineScoreEntity? score,
    bool? refreshing,
  }) {
    return LeaderboardLoadedScoreItem(
      score: score ?? this.score,
      refreshing: refreshing ?? this.refreshing,
    );
  }

  @override
  List<Object?> get props => [score, refreshing];
}

class LeaderboardLoadingScoreItem extends LeaderboardScoreItem
    with EquatableMixin {
  final bool showShimmer;

  LeaderboardLoadingScoreItem({this.showShimmer = true});

  LeaderboardLoadingScoreItem copyWith({
    bool? showShimmer,
  }) {
    return LeaderboardLoadingScoreItem(
      showShimmer: showShimmer ?? this.showShimmer,
    );
  }

  @override
  List<Object?> get props => [
        showShimmer,
      ];
}

extension OnlineScoreEntityListExtension on List<OnlineScoreEntity> {
  List<LeaderboardLoadedScoreItem> toItems() =>
      map((e) => LeaderboardLoadedScoreItem(score: e)).toList();
}
