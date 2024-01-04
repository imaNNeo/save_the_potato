import 'package:flutter/material.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

class ScoreRankNumber extends StatelessWidget {
  final int rank;
  final double size;

  const ScoreRankNumber({
    super.key,
    required this.rank,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GameColors.getRankBgColor(rank),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: size * 0.1),
        child: Center(
          child: Text(
            rank.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameColors.getRankTextColor(rank),
              fontWeight: FontWeight.bold,
              fontSize: rank < 10 ? 24 : 20,
            ),
          ),
        ),
      ),
    );
  }
}
