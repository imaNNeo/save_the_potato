import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/models/leaderboard_entity.dart';
import 'package:save_the_potato/domain/models/presentation_message.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/auth_repository.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';

part 'scores_state.dart';

class ScoresCubit extends Cubit<ScoresState> {
  static const int maxItemsToLoad = 20;
  ScoresCubit(
    this._scoreRepository,
    this._authRepository,
  ) : super(const ScoresState());

  final ScoresRepository _scoreRepository;
  final AuthRepository _authRepository;

  late StreamSubscription _highScoreSubscription;
  late StreamSubscription _userSubscription;

  UserEntity? lastUser;
  Future<void> initialize() async {
    emit(state.copyWith(
      myScore: ValueWrapper(await _scoreRepository.getHighScore()),
    ));
    tryToRefreshLeaderboard();
    _highScoreSubscription =
        _scoreRepository.getHighScoreStream().distinct().listen((event) {
      emit(state.copyWith(
        myScore: ValueWrapper(event),
      ));
    });
    _userSubscription = _authRepository.getUserStream().listen((user) {
      if (lastUser != user && user != null) {
        final userChanged = lastUser?.uid != user.uid;
        if (userChanged) {
          /// User changed, reload leaderboard and everything
          tryToRefreshLeaderboard();
        } else {
          /// It's just a minor change such as nickname,
          /// we update it offline and locally (without fetching everything again)
          _updateUserInShowingData(user);
        }
      }
      lastUser = user;
    });
    await reloadHighScore();
  }

  void _updateUserInShowingData(UserEntity user) {
    final leaderboard = state.leaderboard;
    if (leaderboard != null) {
      final newLeaderboard = leaderboard.copyWith(
        myScore: leaderboard.myScore?.copyWith(
          nickname: user.nickname,
        ),
        scores: leaderboard.scores.map((e) {
          if (e.userId == user.uid) {
            assert(e.isMine);
            return e.copyWith(nickname: user.nickname);
          }
          return e;
        }).toList(),
      );
      emit(state.copyWith(
        leaderboard: ValueWrapper(newLeaderboard),
      ));
    }
  }

  Future<void> reloadHighScore() async {
    final highScore = await _scoreRepository.syncHighScore();
    emit(state.copyWith(
      myScore: ValueWrapper(highScore),
    ));
  }

  void tryToRefreshLeaderboard() async {
    if (state.leaderboardLoading) {
      return;
    }
    try {
      emit(state.copyWith(
        leaderboardLoading: true,
      ));
      final leaderboard = await _scoreRepository.getLeaderboard(
        maxItemsToLoad,
      );
      emit(state.copyWith(
        leaderboard: ValueWrapper(leaderboard),
        leaderboardLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        leaderBoardError: PresentationMessage.fromError(e),
        leaderboardLoading: false,
      ));
      emit(state.copyWith(
        leaderBoardError: PresentationMessage.empty,
      ));
    }
  }

  void onUserScoreClicked() async {
    try {
      final isUserAnonymous = await _authRepository.isUserAnonymous();

      // Anonymous user cannot update nickname
      if (isUserAnonymous) {
        emit(state.copyWith(showAuthDialog: true));
        emit(state.copyWith(showAuthDialog: false));
        return;
      }

      emit(state.copyWith(showNicknameDialog: true));
      emit(state.copyWith(showNicknameDialog: false));
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      emit(state.copyWith(
        leaderBoardError: PresentationMessage.fromError(e),
      ));
      emit(state.copyWith(
        leaderBoardError: PresentationMessage.empty,
      ));
    }
  }

  @override
  Future<void> close() {
    _highScoreSubscription.cancel();
    _userSubscription.cancel();
    return super.close();
  }
}
