import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/extensions/string_extensions.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScoresCubit>().tryToRefreshLeaderboard();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScoresCubit, ScoresState>(
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
                  if (scoresState.leaderBoardError.isNotBlank)
                    Text(scoresState.leaderBoardError),
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
                          return ScoreRow(
                            scoreEntity: leaderboard.scores[index],
                          );
                        },
                        itemCount: leaderboard.scores.length,
                      ),
                    ),
                  if (leaderboard != null &&
                      leaderboard.scores.isEmpty &&
                      !scoresState.leaderboardLoading)
                    const Center(
                      child: Text('No score found!'),
                    ),
                  if (scoresState.leaderboardLoading)
                    const Center(
                      child: CircularProgressIndicator(),
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
