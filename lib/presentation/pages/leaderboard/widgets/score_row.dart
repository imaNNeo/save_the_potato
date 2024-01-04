import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'score_rank_number.dart';

class ScoreRow extends StatelessWidget {
  const ScoreRow({
    super.key,
    required this.scoreEntity,
  }) : super();

  final ScoreEntity scoreEntity;

  @override
  Widget build(BuildContext context) {
    const height = 68.0;
    final isMine = scoreEntity.isMine;

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: GameColors.getLeaderboardStrokeColor(
            context,
            isMine,
            scoreEntity.rank,
          ),
          width: isMine ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ScoreRankNumber(
            rank: scoreEntity.rank,
            size: height * 0.55,
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