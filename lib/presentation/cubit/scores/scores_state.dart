part of 'scores_cubit.dart';

class ScoresState extends Equatable {
  static const int maxItemsToLoad = 20;

  const ScoresState({
    this.myScore,
    this.allShowingScores = const [],
    this.leaderboardLoading = false,
    this.leaderBoardFirstPageError = PresentationMessage.empty,
    this.leaderBoardNextPageError = PresentationMessage.empty,
    this.updateNicknameError = PresentationMessage.empty,
    this.showAuthDialog = false,
    this.showNicknameDialog = false,
    this.scoreShareLoading = false,
    this.scoreShareError = PresentationMessage.empty,
    this.nextPageCountToLoad = maxItemsToLoad,
  });

  final ScoreEntity? myScore;
  final List<LeaderboardScoreItem> allShowingScores;
  final bool leaderboardLoading;
  final PresentationMessage leaderBoardFirstPageError;
  final PresentationMessage leaderBoardNextPageError;
  final PresentationMessage updateNicknameError;
  final bool showAuthDialog;
  final bool showNicknameDialog;
  final bool scoreShareLoading;
  final PresentationMessage scoreShareError;
  final int nextPageCountToLoad;

  ScoresState copyWith({
    ValueWrapper<ScoreEntity>? myScore,
    List<LeaderboardScoreItem>? allShowingScores,
    bool? leaderboardLoading,
    PresentationMessage? leaderBoardFirstPageError,
    PresentationMessage? leaderBoardNextPageError,
    PresentationMessage? updateNicknameError,
    bool? showAuthDialog,
    bool? showNicknameDialog,
    bool? scoreShareLoading,
    PresentationMessage? scoreShareError,
    int? nextPageCountToLoad,
  }) {
    return ScoresState(
      myScore: myScore != null ? myScore.value : this.myScore,
      allShowingScores: allShowingScores ?? this.allShowingScores,
      leaderboardLoading: leaderboardLoading ?? this.leaderboardLoading,
      leaderBoardFirstPageError:
          leaderBoardFirstPageError ?? this.leaderBoardFirstPageError,
      leaderBoardNextPageError:
          leaderBoardNextPageError ?? this.leaderBoardNextPageError,
      updateNicknameError: updateNicknameError ?? this.updateNicknameError,
      showAuthDialog: showAuthDialog ?? this.showAuthDialog,
      showNicknameDialog: showNicknameDialog ?? this.showNicknameDialog,
      scoreShareLoading: scoreShareLoading ?? this.scoreShareLoading,
      scoreShareError: scoreShareError ?? this.scoreShareError,
      nextPageCountToLoad: nextPageCountToLoad ?? this.nextPageCountToLoad,
    );
  }

  @override
  List<Object?> get props => [
        myScore,
        allShowingScores,
        leaderboardLoading,
        leaderBoardFirstPageError,
        leaderBoardNextPageError,
        updateNicknameError,
        showAuthDialog,
        showNicknameDialog,
        scoreShareLoading,
        scoreShareError,
        nextPageCountToLoad,
      ];
}
