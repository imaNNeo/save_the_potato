import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';

part 'scores_state.dart';

class ScoresCubit extends Cubit<ScoresState> {
  ScoresCubit(
    this._scoreRepository,
  ) : super(const ScoresState());

  final ScoresRepository _scoreRepository;

  late StreamSubscription _highScoreSubscription;

  Future<void> initialize() async {
    emit(state.copyWith(
      myScore: ValueWrapper(await _scoreRepository.getHighScore()),
    ));
    _highScoreSubscription =
        _scoreRepository.getHighScoreStream().distinct().listen((event) {
      emit(state.copyWith(
        myScore: ValueWrapper(event),
      ));
    });
  }

  @override
  Future<void> close() {
    _highScoreSubscription.cancel();
    return super.close();
  }
}
