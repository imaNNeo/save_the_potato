part of 'scores_cubit.dart';

class ScoresState extends Equatable {
  const ScoresState({
    this.highScore,
    this.leaderboard,
    this.leaderboardLoading = false,
    this.leaderBoardError = '',
  });

  final HighScoreBundleEntity? highScore;
  final LeaderboardEntity? leaderboard;
  final bool leaderboardLoading;
  final String leaderBoardError;

  ScoresState copyWith({
    ValueWrapper<HighScoreBundleEntity>? highScore,
    ValueWrapper<LeaderboardEntity>? leaderboard,
    bool? leaderboardLoading,
    String? leaderBoardError,
  }) {
    return ScoresState(
      highScore: highScore != null ? highScore.value : this.highScore,
      leaderboard: leaderboard != null ? leaderboard.value : this.leaderboard,
      leaderboardLoading: leaderboardLoading ?? this.leaderboardLoading,
      leaderBoardError: leaderBoardError ?? this.leaderBoardError,
    );
  }

  @override
  List<Object?> get props => [
        highScore,
        leaderboard,
        leaderboardLoading,
        leaderBoardError,
      ];
}
