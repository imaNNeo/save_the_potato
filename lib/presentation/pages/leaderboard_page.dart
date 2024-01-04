import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/extensions/string_extensions.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/auth/auth_cubit.dart';
import 'package:save_the_potato/presentation/cubit/scores/scores_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

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
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
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

  Color _getRankBgColor(int rank) => switch (rank) {
        1 => GameColors.leaderboardGoldenColor,
        2 => GameColors.leaderboardSilverColor,
        3 => GameColors.leaderboardBronzeColor,
        _ => GameColors.leaderboardOtherColor,
      };

  Color _getRankTextColor(int rank) => switch (rank) {
        1 => GameColors.leaderboardGoldenColorText,
        2 => GameColors.leaderboardSilverColorText,
        3 => GameColors.leaderboardBronzeColorText,
        _ => GameColors.leaderboardOtherColorText,
      };

  @override
  Widget build(BuildContext context) {
    const height = 68.0;
    final isMine = scoreEntity.isMine;
    final mineBorderColor = scoreEntity.rank <= 3
        ? _getRankBgColor(scoreEntity.rank)
        : Theme.of(context).colorScheme.primary;
    final normalBorderColor = Theme.of(context).dividerColor.withOpacity(0.3);
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isMine ? mineBorderColor : normalBorderColor,
          width: isMine ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: height * 0.55,
            height: height * 0.55,
            decoration: BoxDecoration(
              color: _getRankBgColor(scoreEntity.rank),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: height * 0.04),
              child: Text(
                scoreEntity.rank.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getRankTextColor(scoreEntity.rank),
                  fontWeight: FontWeight.bold,
                  fontSize: scoreEntity.rank < 10 ? 24 : 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            scoreEntity.nickname,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isMine ? FontWeight.w700 : FontWeight.w500,
              fontSize: 18,
              fontFamily: 'RobotoMono',
            ),
          ),
          Expanded(child: Container()),
          Text(
            AppUtils.getHighScoreRepresentation(scoreEntity.score),
            style: TextStyle(
              color: isMine ? Colors.white : Colors.white.withOpacity(0.8),
              fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
