import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/extensions/string_extensions.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';

class LeaderboardDialogContent extends StatefulWidget {
  const LeaderboardDialogContent({super.key}) : super();

  @override
  State<LeaderboardDialogContent> createState() =>
      _LeaderboardDialogContentState();
}

class _LeaderboardDialogContentState extends State<LeaderboardDialogContent> {
  @override
  void initState() {
    context.read<ScoresCubit>().tryToRefreshLeaderboard();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScoresCubit, ScoresState>(
      builder: (context, scoresState) {
        final leaderboard = scoresState.leaderboard;
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: authState.isAnonymous ? 320 : 680,
              ),
              width: double.infinity,
              child: Stack(
                children: [
                  if (scoresState.leaderBoardError.isNotBlank)
                    Text(scoresState.leaderBoardError),
                  if (leaderboard != null)
                    ListView.builder(
                      itemBuilder: (context, index) {
                        return ScoreRow(
                          scoreEntity: leaderboard.scores[index],
                        );
                      },
                      itemCount: leaderboard.scores.length,
                    ),
                  if (leaderboard != null &&
                      leaderboard.scores.isEmpty &&
                      !scoresState.leaderboardLoading)
                    const Center(
                      child: Text('No score found!'),
                    ),
                  // Center(
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 16.0,
                  //       vertical: 24,
                  //     ),
                  //     child: Column(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         const Icon(
                  //           Icons.emoji_events_outlined,
                  //           size: 104,
                  //           color: Colors.yellow,
                  //         ),
                  //         const SizedBox(height: 16),
                  //         const Text(
                  //           'LOGIN TO SAVE YOUR SCORE',
                  //           style: TextStyle(color: Colors.white, fontSize: 16),
                  //         ),
                  //         const SizedBox(height: 16),
                  //         ElevatedButton(
                  //           onPressed: context.read<AuthCubit>().login,
                  //           child: const Text('LOGIN'),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  if (scoresState.leaderboardLoading)
                    const Center(
                      child: CircularProgressIndicator(),
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

class ScoreRow extends StatelessWidget {
  const ScoreRow({
    super.key,
    required this.scoreEntity,
  }) : super();

  final ScoreEntity scoreEntity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: scoreEntity.isMine ? 4 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            scoreEntity.nickname,
            style: TextStyle(
              color: scoreEntity.isMine
                  ? Colors.white
                  : Colors.white.withOpacity(0.8),
              fontWeight:
                  scoreEntity.isMine ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          Expanded(child: Container()),
          Text(
            AppUtils.getHighScoreRepresentation(scoreEntity.score),
            style: TextStyle(
              color: scoreEntity.isMine
                  ? Colors.white
                  : Colors.white.withOpacity(0.8),
              fontWeight:
                  scoreEntity.isMine ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
