part of 'scores_cubit.dart';

class ScoresState extends Equatable {
  const ScoresState({
    this.myScore,
  });

  final int? myScore;

  ScoresState copyWith({
    ValueWrapper<int>? myScore,
  }) {
    return ScoresState(
      myScore: myScore != null ? myScore.value : this.myScore,
    );
  }

  @override
  List<Object?> get props => [
        myScore,
      ];
}
