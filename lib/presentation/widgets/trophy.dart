import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:save_the_potato/domain/models/game_config_entity.dart';
import 'package:save_the_potato/domain/models/score_entity.dart';
import 'package:save_the_potato/presentation/cubit/configs/configs_cubit.dart';
import 'package:save_the_potato/presentation/game_colors.dart';

import 'new_rank_celebration_shareable_widget.dart';

class Trophy extends StatelessWidget {
  const Trophy({
    super.key,
    required this.score,
    this.nullableGameConfig,
    this.size = 38,
    this.showNickname = true,
  });

  final ScoreEntity? score;
  final double size;
  final bool showNickname;

  /// We need to provide the gameConfig when we want to use it in
  /// the [NewRankCelebrationShareableWidget], Because we don't have access
  /// to the context to retrieve this object in
  /// [NewRankCelebrationShareableWidget],
  /// If it is used in the app widget tree, we don't need to pass it,
  /// we use context to find the ConfigsCubit and the gameConfig.
  final GameConfigEntity? nullableGameConfig;

  @override
  Widget build(BuildContext context) {
    int? rank =
        score is OnlineScoreEntity ? (score as OnlineScoreEntity).rank : null;

    late final GameConfigEntity gameConfig;
    if (nullableGameConfig != null) {
      gameConfig = nullableGameConfig!;
    } else {
      gameConfig = context.read<ConfigsCubit>().state.gameConfig;
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
          if (rank != null &&
              rank <= gameConfig.showNewScoreCelebrationRankThreshold)
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
