import 'package:flutter/material.dart';
import 'package:save_the_potato/domain/app_utils.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'score_rank_number.dart';

class MyScore extends StatelessWidget {
  final ScoreEntity scoreEntity;

  const MyScore({
    super.key,
    required this.scoreEntity,
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: GameColors.getLeaderboardStrokeColor(
        context,
        scoreEntity.isMine,
        scoreEntity.rank,
      ),
      width: 2,
    );
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          left: borderSide,
          top: borderSide,
          right: borderSide,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: 18.0,
          ),
          child: Row(
            children: [
              ScoreRankNumber(
                rank: scoreEntity.rank,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  scoreEntity.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
              Text(
                AppUtils.getHighScoreRepresentation(scoreEntity.score),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}