import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/high_score_bundle.dart';
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
    await reloadHighScore();
    _highScoreSubscription =
        _scoreRepository.getHighScoreStream().listen((event) {
      emit(state.copyWith(
        highScore: ValueWrapper(event),
      ));
    });
  }

  Future<void> reloadHighScore() async {
    final highScore = await _scoreRepository.getHighScore();
    emit(state.copyWith(
      highScore: ValueWrapper(highScore),
    ));
  }

  void updateHighScore(int newScoreMilliseconds) async {
    if (newScoreMilliseconds <= (state.highScore?.highScore ?? 0)) {
      return;
    }
    await _scoreRepository.saveScore(newScoreMilliseconds);
    await reloadHighScore();
  }

  @override
  Future<void> close() {
    _highScoreSubscription.cancel();
    return super.close();
  }
}
