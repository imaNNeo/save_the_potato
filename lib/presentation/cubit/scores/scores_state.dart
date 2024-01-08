part of 'scores_cubit.dart';

class ScoresState extends Equatable {
  const ScoresState({
    this.highScore,
    this.leaderboard,
    this.leaderboardLoading = false,
    this.leaderBoardError = PresentationMessage.empty,
    this.showAuthDialog = false,
    this.showNicknameDialog = false,
  });

  final int? highScore;
  final LeaderboardEntity? leaderboard;
  final bool leaderboardLoading;
  final PresentationMessage leaderBoardError;
  final bool showAuthDialog;
  final bool showNicknameDialog;

  ScoresState copyWith({
    ValueWrapper<int>? highScore,
    ValueWrapper<LeaderboardEntity>? leaderboard,
    bool? leaderboardLoading,
    PresentationMessage? leaderBoardError,
    bool? showAuthDialog,
    bool? showNicknameDialog,
  }) =>
      ScoresState(
        highScore: highScore != null ? highScore.value : this.highScore,
        leaderboard: leaderboard != null ? leaderboard.value : this.leaderboard,
        leaderboardLoading: leaderboardLoading ?? this.leaderboardLoading,
        leaderBoardError: leaderBoardError ?? this.leaderBoardError,
        showAuthDialog: showAuthDialog ?? this.showAuthDialog,
        showNicknameDialog: showNicknameDialog ?? this.showNicknameDialog,
      );

  @override
  List<Object?> get props => [
        highScore,
        leaderboard,
        leaderboardLoading,
        leaderBoardError,
        showAuthDialog,
        showNicknameDialog,
      ];
}
