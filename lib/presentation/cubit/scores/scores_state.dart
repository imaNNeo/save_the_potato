part of 'scores_cubit.dart';

class ScoresState extends Equatable {
  const ScoresState({
    this.myScore,
    this.leaderboard,
    this.leaderboardLoading = false,
    this.leaderBoardError = PresentationMessage.empty,
    this.showAuthDialog = false,
    this.showNicknameDialog = false,
  });

  final ScoreEntity? myScore;
  final LeaderboardEntity? leaderboard;
  final bool leaderboardLoading;
  final PresentationMessage leaderBoardError;
  final bool showAuthDialog;
  final bool showNicknameDialog;

  ScoresState copyWith({
    ValueWrapper<ScoreEntity>? myScore,
    ValueWrapper<LeaderboardEntity>? leaderboard,
    bool? leaderboardLoading,
    PresentationMessage? leaderBoardError,
    bool? showAuthDialog,
    bool? showNicknameDialog,
  }) {
    if (leaderboard != null && leaderboard.value != null && myScore == null) {
      myScore = ValueWrapper(leaderboard.value!.myScore);
    }
    return ScoresState(
      myScore: myScore != null ? myScore.value : this.myScore,
      leaderboard: leaderboard != null ? leaderboard.value : this.leaderboard,
      leaderboardLoading: leaderboardLoading ?? this.leaderboardLoading,
      leaderBoardError: leaderBoardError ?? this.leaderBoardError,
      showAuthDialog: showAuthDialog ?? this.showAuthDialog,
      showNicknameDialog: showNicknameDialog ?? this.showNicknameDialog,
    );
  }

  @override
  List<Object?> get props => [
        myScore,
        leaderboard,
        leaderboardLoading,
        leaderBoardError,
        showAuthDialog,
        showNicknameDialog,
      ];
}
