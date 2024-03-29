import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:save_the_potato/domain/game_constants.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/configs/configs_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

class Trophy extends StatelessWidget {
  const Trophy({
    super.key,
    required this.score,
    this.size = 38,
    this.showNickname = true,
  });

  final ScoreEntity? score;
  final double size;
  final bool showNickname;

  @override
  Widget build(BuildContext context) {
    int? rank =
        score is OnlineScoreEntity ? (score as OnlineScoreEntity).rank : null;
    final threshold = context
        .read<ConfigsCubit>()
        .state
        .gameConfig
        .showNewScoreCelebrationRankThreshold;
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
          if (rank != null && rank <= threshold)
            Align(
              alignment: const Alignment(0, -0.7),
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: rank < 10 ? FontWeight.w400 : FontWeight.w100,
                  fontFamily: 'Cookies',
                  letterSpacing: -2,
                  color: GameColors.leaderboardGoldenColorText,
                ),
              ),
            ),
          if (showNickname)
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
