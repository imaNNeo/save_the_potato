import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/high_score_bundle.dart';
import 'package:save_the_potato/domain/models/leaderboard_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';

part 'scores_state.dart';

class ScoresCubit extends Cubit<ScoresState> {
  ScoresCubit(
    this._scoreRepository,
  ) : super(const ScoresState()) {
    initialize();
  }

  final ScoresRepository _scoreRepository;

  late StreamSubscription _highScoreSubscription;

  Future<void> initialize() async {
    _highScoreSubscription =
        _scoreRepository.getHighScoreStream().listen((event) {
      emit(state.copyWith(
        highScore: ValueWrapper(event),
      ));
    });
    await reloadHighScore();
  }

  Future<void> reloadHighScore() async {
    final highScore = await _scoreRepository.syncHighScore();
    emit(state.copyWith(
      highScore: ValueWrapper(highScore),
    ));
  }

  void tryToRefreshLeaderboard() async {
    try {
      emit(state.copyWith(
        leaderboardLoading: true,
      ));
      final leaderboard = await _scoreRepository.getLeaderboard();
      emit(state.copyWith(
        leaderboard: ValueWrapper(leaderboard),
        leaderboardLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        leaderBoardError: e.toString(),
        leaderboardLoading: false,
      ));
    }
  }

  @override
  Future<void> close() {
    _highScoreSubscription.cancel();
    return super.close();
  }
}
