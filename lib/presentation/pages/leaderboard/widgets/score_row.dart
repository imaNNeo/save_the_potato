import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'score_rank_number.dart';

class ScoreRow extends StatelessWidget {
  static const height = 68.0;
  const ScoreRow({
    super.key,
    required this.scoreEntity,
    required this.loading,
  }) : super();

  final ScoreEntity scoreEntity;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    const height = 68.0;
    final isMine = scoreEntity.isMine;

    final rawWidget = Container(
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
          Expanded(
            child: Text(
              scoreEntity.nickname,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isMine ? FontWeight.w700 : FontWeight.w500,
                fontSize: 18,
                fontFamily: 'RobotoMono',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
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

    if (!loading) {
      return rawWidget;
    }
    return rawWidget
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          color: Colors.white,
          blendMode: BlendMode.dstOut,
          duration: const Duration(seconds: 2),
          angle: 45,
        );
  }
}

class ScoreRowShimmer extends StatelessWidget {
  const ScoreRowShimmer({
    super.key,
  }) : super();

  @override
  Widget build(BuildContext context) {
    const height = ScoreRow.height;
    final color = Colors.white.withOpacity(0.5);

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: height * 0.55,
            height: height * 0.55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 24),
          Container(
            height: 16,
            width: 48,
            color: color,
          ),
        ],
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          size: 5,
          color: Colors.white,
          blendMode: BlendMode.dstOut,
          duration: const Duration(seconds: 2),
          angle: 45,
        );
  }
}
