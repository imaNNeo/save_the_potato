import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:save_the_potato/domain/models/presentation_message.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/leaderboard_score_item.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/widgets/error_retry_box.dart';
import 'package:save_the_potato/presentation/widgets/game_icon_button.dart';

import 'widgets/my_score.dart';
import 'widgets/score_row.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key}) : super();

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final lastScoreIsVisible = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - (ScoreRow.height * 1.5);
      if (lastScoreIsVisible) {
        context.read<ScoresCubit>().tryToLoadNextPage();
      }
    });
    context.read<ScoresCubit>().onLeaderboardPageOpen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scoresCubit = context.read<ScoresCubit>();
    return BlocConsumer<ScoresCubit, ScoresState>(
      listener: (context, scoresState) {
        if (scoresState.updateNicknameError.isNotEmpty) {
          scoresState.updateNicknameError.showAsToast(
            context,
          );
        }
        if (scoresState.leaderBoardNextPageError.isNotEmpty) {
          scoresState.leaderBoardNextPageError.showAsToast(
            context,
          );
        }
        if (scoresState.scoreShareError.isNotEmpty) {
          scoresState.scoreShareError.showAsToast(
            context,
          );
        }
      },
      builder: (context, scoresState) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'LEADERBOARD',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                leading: GameIconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  svgAssetName: 'arrow_left.svg',
                ),
              ),
              body: Stack(
                children: [
                  SafeArea(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 16.0,
                        right: 16.0,
                        bottom: 96,
                      ),
                      itemBuilder: (context, index) {
                        final item = scoresState.allShowingScores[index];
                        return switch (item) {
                          LeaderboardLoadedScoreItem() => ScoreRow(
                              scoreEntity: item.score,
                              loading: item.refreshing,
                            ),
                          LeaderboardLoadingScoreItem(
                            showShimmer: bool showShimmer
                          ) =>
                            ScoreRowTemplateShimmer(
                              showShimmer: showShimmer,
                            ),
                        };
                      },
                      itemCount: scoresState.allShowingScores.length,
                    ),
                  ),
                  if (scoresState.allShowingScores.isEmpty &&
                      !scoresState.leaderboardLoading)
                    scoresState.leaderBoardFirstPageError.isNotEmpty
                        ? Center(
                            child: ErrorRetryBox(
                              error: PresentationMessage.raw(
                                'Could not load leaderboard!\nPlease try again',
                              ),
                              onRetry: scoresCubit.retryLeaderboardClicked,
                            ),
                          )
                        : const Center(
                            child: Text('No score found!'),
                          ),
                  if (scoresState.myScore is OnlineScoreEntity)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: MyScore(
                        scoreEntity: scoresState.myScore as OnlineScoreEntity,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
