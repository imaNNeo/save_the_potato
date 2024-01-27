import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/analytics_helper.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/extensions/list_extension.dart';
import 'package:save_the_potato/domain/models/presentation_message.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/domain/models/user_entity.dart';
import 'package:save_the_potato/domain/models/value_wrapper.dart';
import 'package:save_the_potato/domain/repository/auth_repository.dart';
import 'package:save_the_potato/domain/repository/configs_repository.dart';
import 'package:save_the_potato/domain/repository/scores_repository.dart';
import 'package:save_the_potato/presentation/cubit/scores/leaderboard_score_item.dart';

part 'scores_state.dart';

class ScoresCubit extends Cubit<ScoresState> {
  ScoresCubit(
    this._scoreRepository,
    this._configsRepository,
    this._authRepository,
    this._analyticsHelper,
  ) : super(const ScoresState());

  final ScoresRepository _scoreRepository;
  final ConfigsRepository _configsRepository;
  final AuthRepository _authRepository;
  final AnalyticsHelper _analyticsHelper;

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
    final newShowingItems = state.allShowingScores.map((e) {
      if (e is LeaderboardLoadedScoreItem) {
        if (e.score.userId == user.uid) {
          assert(e.score.isMine);
          return e.copyWith(
            score: e.score.copyWith(
              nickname: user.nickname,
            ),
          );
        }
      }
      return e;
    }).toList();
    final newMyScore = state.myScore is OnlineScoreEntity
        ? (state.myScore as OnlineScoreEntity).copyWith(
            nickname: user.nickname,
          )
        : state.myScore;
    emit(state.copyWith(
      allShowingScores: newShowingItems,
      myScore: ValueWrapper(newMyScore),
    ));
  }

  Future<void> reloadHighScore() async {
    final highScore = await _scoreRepository.syncHighScore();
    emit(state.copyWith(
      myScore: ValueWrapper(highScore),
    ));
  }

  Future<bool> tryToRefreshLeaderboard() async {
    if (state.leaderboardLoading) {
      return false;
    }
    return await _getLeaderboardItems(pageLastId: null);
  }

  Future<bool> _getLeaderboardItems({
    required String? pageLastId,
  }) async {
    if (state.leaderboardLoading) {
      return false;
    }
    emit(state.copyWith(
      leaderboardLoading: true,
    ));
    bool isFirstPage = pageLastId == null;
    if (isFirstPage) {
      emit(const ScoresState().copyWith(
        leaderBoardFirstPageError: PresentationMessage.empty,
        allShowingScores: List.generate(
          ScoresState.maxItemsToLoad,
          (index) => LeaderboardLoadingScoreItem(),
        ),
      ));
    } else {
      _updateLoadingItemShowShimmer(true);
    }
    try {
      emit(state.copyWith(
        leaderboardLoading: true,
      ));
      final leaderboardResponse = await _scoreRepository.getLeaderboard(
        ScoresState.maxItemsToLoad,
        pageLastId,
      );
      final newLoadedItems = leaderboardResponse.scores.toItems();
      final newShowingItems = <LeaderboardScoreItem>[];
      if (!isFirstPage) {
        newShowingItems.addAll(
          state.allShowingScores.whereType<LeaderboardLoadedScoreItem>(),
        );
      }
      newShowingItems.addAll([
        ...newLoadedItems,
        if (leaderboardResponse.pageData.hasMore) LeaderboardLoadingScoreItem(),
      ]);

      emit(state.copyWith(
        allShowingScores: newShowingItems,
        leaderboardLoading: false,
        myScore: ValueWrapper(leaderboardResponse.myScore),
      ));
      return true;
    } catch (e) {
      if (isFirstPage) {
        emit(state.copyWith(
          leaderBoardFirstPageError: PresentationMessage.fromError(e),
          allShowingScores: [],
          leaderboardLoading: false,
        ));
      } else {
        _updateLoadingItemShowShimmer(false);
        emit(state.copyWith(
          leaderBoardNextPageError: PresentationMessage.fromError(e),
          leaderboardLoading: false,
        ));
        emit(state.copyWith(
          leaderBoardNextPageError: PresentationMessage.empty,
        ));
      }

      return false;
    }
  }

  void onLeaderboardPageOpen() async {
    _analyticsHelper.logLeaderboardPageOpen();
    await _tryToLoadFirstPage();
  }

  Future<void> _tryToLoadFirstPage() async {
    final int startTime = DateTime.now().millisecondsSinceEpoch;
    if (await tryToRefreshLeaderboard()) {
      final int duration = DateTime.now().millisecondsSinceEpoch - startTime;
      _analyticsHelper.logLeaderboardPageLoad(duration);
    }
  }

  void updateNickname() async {
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
        updateNicknameError: PresentationMessage.fromError(e),
      ));
      emit(state.copyWith(
        updateNicknameError: PresentationMessage.empty,
      ));
    }
  }

  void shareScore(OnlineScoreEntity scoreEntity) async {
    emit(state.copyWith(
      scoreShareLoading: true,
    ));
    try {
      await AppUtils.shareScore(
        score: scoreEntity,
        gameConfig: await _configsRepository.getGameConfig(),
      );
      emit(state.copyWith(
        scoreShareLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        scoreShareLoading: false,
        scoreShareError: PresentationMessage.fromError(e),
      ));
      emit(state.copyWith(
        scoreShareError: PresentationMessage.empty,
      ));
    }
  }

  void tryToLoadNextPage() async {
    if (state.leaderboardLoading) {
      return;
    }
    final hasMore = state.allShowingScores.last is LeaderboardLoadingScoreItem;
    if (!hasMore) {
      return;
    }

    _loadNextPage();
  }

  void _loadNextPage() async {
    assert(!state.leaderboardLoading);
    final lastLoadedItem =
        state.allShowingScores.whereType<LeaderboardLoadedScoreItem>().last;
    await _getLeaderboardItems(pageLastId: lastLoadedItem.score.userId);
  }

  void retryLeaderboardClicked() async {
    await _tryToLoadFirstPage();
  }

  void _updateLoadingItemShowShimmer(bool showShimmer) {
    final lastItem = state.allShowingScores.last;
    if (lastItem is LeaderboardLoadingScoreItem) {
      final newItems = state.allShowingScores.updateAndReturn(
        state.allShowingScores.length - 1,
        lastItem.copyWith(
          showShimmer: showShimmer,
        ),
      );
      emit(state.copyWith(allShowingScores: newItems));
    }
  }

  @override
  Future<void> close() {
    _highScoreSubscription.cancel();
    _userSubscription.cancel();
    return super.close();
  }
}
