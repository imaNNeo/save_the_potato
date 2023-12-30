part of 'scores_cubit.dart';

class ScoresState extends Equatable {
  const ScoresState({this.highScore});

  final HighScoreBundleEntity? highScore;

  ScoresState copyWith({
    ValueWrapper<HighScoreBundleEntity>? highScore,
  }) {
    return ScoresState(
      highScore: highScore != null ? highScore.value : this.highScore,
    );
  }

  @override
  List<Object?> get props => [
        highScore,
      ];
}
