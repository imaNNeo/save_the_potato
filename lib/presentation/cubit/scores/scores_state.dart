part of 'scores_cubit.dart';

class ScoresState extends Equatable {
  const ScoresState({
    this.myScore,
    this.leaderboard,
    this.leaderboardLoading = false,
    this.leaderBoardError = PresentationMessage.empty,
    this.showAuthDialog = false,
    this.showNicknameDialog = false,
    this.scoreShareLoading = false,
    this.scoreShareError = PresentationMessage.empty,
  });

  final ScoreEntity? myScore;
  final LeaderboardEntity? leaderboard;
  final bool leaderboardLoading;
  final PresentationMessage leaderBoardError;
  final bool showAuthDialog;
  final bool showNicknameDialog;
  final bool scoreShareLoading;
  final PresentationMessage scoreShareError;

  ScoresState copyWith({
    ValueWrapper<ScoreEntity>? myScore,
    ValueWrapper<LeaderboardEntity>? leaderboard,
    bool? leaderboardLoading,
    PresentationMessage? leaderBoardError,
    bool? showAuthDialog,
    bool? showNicknameDialog,
    bool? scoreShareLoading,
    PresentationMessage? scoreShareError,
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
      scoreShareLoading: scoreShareLoading ?? this.scoreShareLoading,
      scoreShareError: scoreShareError ?? this.scoreShareError,
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
        scoreShareLoading,
        scoreShareError,
      ];
}
