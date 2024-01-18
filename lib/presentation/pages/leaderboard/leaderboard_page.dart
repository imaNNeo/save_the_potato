import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';

import 'widgets/my_score.dart';
import 'widgets/score_row.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key}) : super();

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    context.read<ScoresCubit>().tryToRefreshLeaderboard();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScoresCubit, ScoresState>(
      listener: (context, scoresState) {
        if (scoresState.leaderBoardError.isNotEmpty) {
          scoresState.leaderBoardError.showAsToast(
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
        final leaderboard = scoresState.leaderboard;
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
              ),
              body: Stack(
                children: [
                  if (leaderboard == null && scoresState.leaderboardLoading)
                    SafeArea(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ScoresCubit.maxItemsToLoad,
                        itemBuilder: (_, __) => const ScoreRowShimmer(),
                      ),
                    ),
                  if (leaderboard != null)
                    SafeArea(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 16.0,
                          right: 16.0,
                          bottom: 96,
                        ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(
                                left: 6.0,
                                bottom: 8.0,
                              ),
                              child: Text('Top ${ScoresCubit.maxItemsToLoad}:'),
                            );
                          }
                          return ScoreRow(
                            scoreEntity: leaderboard.scores[index - 1],
                            loading: scoresState.leaderboardLoading,
                          );
                        },
                        itemCount: leaderboard.scores.length + 1,
                      ),
                    ),
                  if (leaderboard != null &&
                      leaderboard.scores.isEmpty &&
                      !scoresState.leaderboardLoading)
                    const Center(
                      child: Text('No score found!'),
                    ),
                  if (scoresState.leaderboard?.myScore != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: MyScore(
                        scoreEntity: scoresState.leaderboard!.myScore!,
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
}
