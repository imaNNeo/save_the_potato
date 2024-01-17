import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

class Trophy extends StatelessWidget {
  const Trophy({
    super.key,
    required this.score,
    this.size = 38,
  });

  final ScoreEntity? score;
  final double size;

  @override
  Widget build(BuildContext context) {
    int? rank =
        score is OnlineScoreEntity ? (score as OnlineScoreEntity).rank : null;
    if (rank != null && rank > 99) {
      rank = 99;
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SvgPicture.asset(
            'assets/images/trophy/trophy.svg',
            width: size,
            colorFilter: const ColorFilter.mode(
              GameColors.leaderboardGoldenColor,
              BlendMode.srcATop,
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.9),
            child: Text(
              rank == null ? '' : rank.toString(),
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: rank == null
                    ? null
                    : rank < 10
                        ? FontWeight.w900
                        : FontWeight.w400,
                fontFamily: 'Roboto',
                letterSpacing: -2,
                color: GameColors.leaderboardGoldenColorText,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.75),
            child: SizedBox(
              width: size * 0.50,
              height: size * 0.12,
              child: FittedBox(
                child: Center(
                  child: Text(
                    score == null
                        ? ''
                        : score is OnlineScoreEntity
                            ? (score as OnlineScoreEntity).nickname
                            : '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Roboto',
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
